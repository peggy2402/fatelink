import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../utils/constants.dart';
import '../utils/toast_utils.dart';
import '../../services/api_service.dart';
import 'voice_player_manager.dart';

/// Kết quả sau khi ghi âm hoàn tất
class VoiceRecordResult {
  final String localPath;
  final int durationMs;
  final List<int> waveform; // Mảng 40 số từ 0 đến 31
  final int fileSizeBytes;

  const VoiceRecordResult({
    required this.localPath,
    required this.durationMs,
    required this.waveform,
    required this.fileSizeBytes,
  });
}

/// Dịch vụ quản lý Ghi âm Microphone thực tế (chuẩn Telegram)
/// - Xin quyền Micro qua `permission_handler`
/// - Dừng mọi audio phát trước khi ghi
/// - Đo thời gian bằng Stopwatch chuẩn mili-giây
/// - Thu thập biên độ thật (decibels) qua `onAmplitudeChanged` -> chuẩn hóa về 40 cột
/// - Upload tệp qua Multipart/Form-Data lên Cloudinary CDN
class VoiceNoteService {
  static final VoiceNoteService _instance = VoiceNoteService._internal();
  factory VoiceNoteService() => _instance;
  VoiceNoteService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final Stopwatch _stopwatch = Stopwatch();

  StreamSubscription? _amplitudeSub;
  final List<double> _amplitudeSamples = []; // Lưu các giá trị dB thật
  String? _currentLocalPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  /// 1. Kiểm tra và yêu cầu cấp quyền Microphone thực tế
  Future<bool> checkAndRequestPermission(BuildContext? context) async {
    try {
      debugPrint('🎙️ [VoiceNoteService] 1. Kiểm tra quyền Microphone qua permission_handler');
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (status.isGranted) {
        debugPrint('✅ [VoiceNoteService] Quyền Microphone đã được cấp!');
        return true;
      }

      if (status.isPermanentlyDenied && context != null && context.mounted) {
        debugPrint('⚠️ [VoiceNoteService] Quyền Microphone bị từ chối vĩnh viễn -> Gợi ý mở Settings');
        ToastUtil.showError(context, 'Vui lòng mở Cài đặt ứng dụng để cấp quyền Microphone.');
        await openAppSettings();
        return false;
      }

      if (context != null && context.mounted) {
        ToastUtil.showError(context, 'Ứng dụng cần quyền Microphone để gửi tin nhắn thoại.');
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi xin quyền micro: $e');
      return false;
    }
  }

  /// 2. Bắt đầu ghi âm với âm thanh chất lượng cao AAC LC .m4a
  Future<bool> startRecording(BuildContext? context) async {
    try {
      // Dừng mọi âm thanh đang phát để tránh tiếng micro bị dội
      await VoicePlayerManager().stopAll();

      final hasPermission = await checkAndRequestPermission(context);
      if (!hasPermission) return false;

      // Hủy phiên ghi cũ nếu có sót
      await cancelRecording();

      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentLocalPath = '${tempDir.path}/$fileName';
      _amplitudeSamples.clear();

      debugPrint('🎙️ [VoiceNoteService] 2. Khởi động bộ ghi âm tại: $_currentLocalPath');
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: _currentLocalPath!,
      );

      _stopwatch.reset();
      _stopwatch.start();
      _isRecording = true;

      // Lắng nghe biên độ âm thanh thật cứ mỗi 100ms
      _amplitudeSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
        // amp.current là giá trị dB (từ -60dB đến 0dB)
        _amplitudeSamples.add(amp.current);
      });

      return true;
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi khi startRecording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// 3. Tạm dừng ghi âm (khi ở chế độ Lock)
  Future<void> pauseRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.pause();
        _stopwatch.stop();
        debugPrint('⏸️ [VoiceNoteService] Đã tạm dừng ghi âm');
      }
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi pauseRecording: $e');
    }
  }

  /// 4. Tiếp tục ghi âm (khi ở chế độ Lock)
  Future<void> resumeRecording() async {
    try {
      if (await _recorder.isPaused()) {
        await _recorder.resume();
        _stopwatch.start();
        debugPrint('▶️ [VoiceNoteService] Đã tiếp tục ghi âm');
      }
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi resumeRecording: $e');
    }
  }

  /// 5. Dừng ghi âm và trả về VoiceRecordResult với waveform 40 cột
  Future<VoiceRecordResult?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      _stopwatch.stop();
      final durationMs = _stopwatch.elapsedMilliseconds;
      _amplitudeSub?.cancel();
      _amplitudeSub = null;

      final path = await _recorder.stop();
      _isRecording = false;
      final effectivePath = path ?? _currentLocalPath;

      if (effectivePath == null) {
        debugPrint('⚠️ [VoiceNoteService] Không tìm thấy file âm thanh sau khi stop');
        return null;
      }

      final file = File(effectivePath);
      final exists = await file.exists();
      if (!exists) {
        debugPrint('⚠️ [VoiceNoteService] File ghi âm không tồn tại trên đĩa');
        return null;
      }

      final fileBytes = await file.length();
      debugPrint('🎙️ [VoiceNoteService] 3. Đã dừng ghi. Thời lượng: ${durationMs}ms, Size: $fileBytes bytes, Path: $effectivePath');

      // Chuẩn hóa biên độ thành 40 cột sóng âm (0 - 31)
      final normalizedWaveform = _generateNormalizedWaveform(_amplitudeSamples, 40);

      return VoiceRecordResult(
        localPath: effectivePath,
        durationMs: durationMs,
        waveform: normalizedWaveform,
        fileSizeBytes: fileBytes,
      );
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi stopRecording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// 6. Hủy bản ghi âm và xóa file tạm
  Future<void> cancelRecording() async {
    try {
      _stopwatch.stop();
      _amplitudeSub?.cancel();
      _amplitudeSub = null;
      _isRecording = false;

      if (await _recorder.isRecording() || await _recorder.isPaused()) {
        await _recorder.cancel();
      }

      if (_currentLocalPath != null) {
        final file = File(_currentLocalPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ [VoiceNoteService] Đã xóa file ghi âm tạm: $_currentLocalPath');
        }
        _currentLocalPath = null;
      }
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi cancelRecording: $e');
    }
  }

  /// 7. Upload tệp âm thanh lên Cloudinary CDN qua Multipart/Form-Data
  /// TUYỆT ĐỐI KHÔNG trả về local file path nếu lỗi! Nếu lỗi trả về null.
  Future<String?> uploadVoiceNote(
    String localPath, {
    BuildContext? context,
  }) =>
      uploadVoiceFile(context: context, localPath: localPath);

  Future<String?> uploadVoiceFile({
    required BuildContext? context,
    required String localPath,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint('⚠️ [VoiceNoteService] File không tồn tại để upload: $localPath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('☁️ [VoiceNoteService] 4. Bắt đầu upload multipart Cloudinary: $localPath ($fileSize bytes)');

      final url = '${AppConstants.baseUrl}/${AppConstants.uploadVoice}';
      final res = await ApiService.uploadFile(
        url,
        localPath,
        context: context,
        fieldName: 'file',
        fields: {'folder': 'fatelink/voice_notes'},
      );

      if (res != null && res['data'] != null && res['data']['url'] != null) {
        final cloudUrl = res['data']['url'].toString();
        debugPrint('✅ [VoiceNoteService] 5. Upload Cloudinary thành công: $cloudUrl');
        return cloudUrl;
      }

      debugPrint('⚠️ [VoiceNoteService] Upload trả về dữ liệu rỗng hoặc lỗi từ server');
      return null;
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi uploadVoiceFile: $e');
      return null;
    }
  }

  /// Chuẩn hóa mảng mẫu biên độ dB thành mảng đúng [count] cột có giá trị 0..31
  List<int> _generateNormalizedWaveform(List<double> rawSamples, int count) {
    if (rawSamples.isEmpty) {
      return List<int>.generate(count, (i) => 4 + (i % 6));
    }

    // Chuyển dB (thường từ -60dB đến 0dB) thành thang 0.0 - 1.0
    final linear = rawSamples.map((db) {
      if (db.isNaN || db.isInfinite) return 0.05;
      final clamped = db.clamp(-55.0, 0.0);
      return (clamped + 55.0) / 55.0; // 0.0 -> 1.0
    }).toList();

    // Rút gọn hoặc nội suy thành đúng [count] điểm
    final result = <int>[];
    final chunkSize = linear.length / count;

    for (int i = 0; i < count; i++) {
      final startIdx = (i * chunkSize).floor().clamp(0, linear.length - 1);
      final endIdx = ((i + 1) * chunkSize).ceil().clamp(startIdx + 1, linear.length);
      final chunk = linear.sublist(startIdx, min(endIdx, linear.length));

      double avg = 0.05;
      if (chunk.isNotEmpty) {
        avg = chunk.reduce((a, b) => a + b) / chunk.length;
      }

      // Map vào khoảng 2 - 31 (giữ tối thiểu 2dp để cột không bị biến mất)
      final barHeightInt = (avg * 31).round().clamp(2, 31);
      result.add(barHeightInt);
    }

    return result;
  }

  void dispose() {
    _amplitudeSub?.cancel();
    _recorder.dispose();
  }
}
