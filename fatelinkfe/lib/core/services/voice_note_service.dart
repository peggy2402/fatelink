import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/constants.dart';
import '../utils/secure_storage_helper.dart';
import '../../services/api_service.dart';

/// Dịch vụ quản lý Ghi âm và Phát tin nhắn thoại thực tế (VoiceNoteService):
/// - Sử dụng phần cứng Microphone với thư viện `record` (AAC LC .m4a chất lượng cao)
/// - Upload file âm thanh lên Cloudinary CDN qua Backend API `/upload/voice`
/// - Phát âm thanh qua loa / tai nghe với thư viện `audioplayers`
class VoiceNoteService {
  static final VoiceNoteService _instance = VoiceNoteService._internal();
  factory VoiceNoteService() => _instance;
  VoiceNoteService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _currentLocalRecordingPath;
  String? _currentlyPlayingUrl;

  AudioPlayer get player => _audioPlayer;
  String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  /// Kiểm tra và yêu cầu cấp quyền Microphone thực tế
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi kiểm tra quyền micro: $e');
      return false;
    }
  }

  /// Bắt đầu ghi âm file .m4a vào thư mục tạm của thiết bị
  Future<String?> startRecording() async {
    try {
      final hasGranted = await hasPermission();
      if (!hasGranted) {
        debugPrint('⚠️ [VoiceNoteService] Quyền micro bị từ chối');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${tempDir.path}/$fileName';
      _currentLocalRecordingPath = filePath;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      debugPrint('🎙️ [VoiceNoteService] Đang ghi âm tại: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi bắt đầu ghi âm: $e');
      return null;
    }
  }

  /// Tạm dừng ghi âm
  Future<void> pauseRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.pause();
      }
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi pause ghi âm: $e');
    }
  }

  /// Tiếp tục ghi âm
  Future<void> resumeRecording() async {
    try {
      if (await _recorder.isPaused()) {
        await _recorder.resume();
      }
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi resume ghi âm: $e');
    }
  }

  /// Dừng ghi âm và trả về đường dẫn file .m4a thực tế
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      debugPrint('🎙️ [VoiceNoteService] Đã dừng ghi âm, file lưu tại: $path');
      return path ?? _currentLocalRecordingPath;
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi dừng ghi âm: $e');
      return _currentLocalRecordingPath;
    }
  }

  /// Hủy bản ghi âm và xóa file tạm
  Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
      if (_currentLocalRecordingPath != null) {
        final file = File(_currentLocalRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentLocalRecordingPath = null;
      }
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi hủy ghi âm: $e');
    }
  }

  /// Upload file âm thanh lên Cloudinary CDN thông qua Backend NestJS
  Future<String?> uploadVoiceFile({
    required BuildContext context,
    required String localPath,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint('⚠️ [VoiceNoteService] File ghi âm không tồn tại: $localPath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64Audio = 'data:audio/m4a;base64,${base64Encode(bytes)}';

      final token = await SecureStorageHelper.read('accessToken');
      if (token == null) {
        debugPrint('⚠️ [VoiceNoteService] Không tìm thấy accessToken');
        return null;
      }

      final url = '${AppConstants.baseUrl}/${AppConstants.uploadVoice}';
      if (!context.mounted) return null;

      final res = await ApiService.post(
        url,
        context,
        token: token,
        body: {
          'audio': base64Audio,
          'folder': 'fatelink/voice_notes',
        },
        showLoading: false,
      );

      if (res != null && res['data'] != null && res['data']['url'] != null) {
        final cloudUrl = res['data']['url'].toString();
        debugPrint('☁️ [VoiceNoteService] Upload voice note thành công: $cloudUrl');
        return cloudUrl;
      }
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi upload voice file: $e');
    }
    return null;
  }

  /// Phát âm thanh từ URL hoặc đường dẫn file cục bộ
  Future<void> playAudio({
    required String audioSource,
    VoidCallback? onComplete,
  }) async {
    try {
      if (_currentlyPlayingUrl == audioSource && _audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.pause();
        return;
      }

      _currentlyPlayingUrl = audioSource;
      await _audioPlayer.stop();

      if (audioSource.startsWith('http://') || audioSource.startsWith('https://')) {
        await _audioPlayer.play(UrlSource(audioSource));
      } else {
        await _audioPlayer.play(DeviceFileSource(audioSource));
      }

      _audioPlayer.onPlayerComplete.listen((_) {
        _currentlyPlayingUrl = null;
        onComplete?.call();
      });
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi phát âm thanh: $e');
    }
  }

  /// Tạm dừng hoặc dừng hẳn phát âm thanh
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _currentlyPlayingUrl = null;
    } catch (e) {
      debugPrint('⚠️ [VoiceNoteService] Lỗi dừng phát âm thanh: $e');
    }
  }

  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
  }
}
