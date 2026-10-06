import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

enum VoicePlayStatus {
  idle,
  loading,
  playing,
  paused,
  error,
}

class VoicePlayerState {
  final String? activeMessageId;
  final VoicePlayStatus status;
  final int positionMs;
  final int totalDurationMs;
  final double speed; // 1.0, 1.5, 2.0
  final String? errorMessage;

  const VoicePlayerState({
    this.activeMessageId,
    this.status = VoicePlayStatus.idle,
    this.positionMs = 0,
    this.totalDurationMs = 0,
    this.speed = 1.0,
    this.errorMessage,
  });

  VoicePlayerState copyWith({
    String? activeMessageId,
    VoicePlayStatus? status,
    int? positionMs,
    int? totalDurationMs,
    double? speed,
    String? errorMessage,
  }) {
    return VoicePlayerState(
      activeMessageId: activeMessageId ?? this.activeMessageId,
      status: status ?? this.status,
      positionMs: positionMs ?? this.positionMs,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      speed: speed ?? this.speed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Singleton quản lý duy nhất 1 AudioPlayer phát âm thanh toàn app (chuẩn Telegram)
/// - Đảm bảo chỉ MỘT tin nhắn phát tại một thời điểm
/// - Bấm tin khác tự động dừng tin trước và reset vị trí
/// - Hỗ trợ seek (tua) và thay đổi tốc độ (1x, 1.5x, 2x)
class VoicePlayerManager {
  static final VoicePlayerManager _instance = VoicePlayerManager._internal();
  factory VoicePlayerManager() => _instance;
  VoicePlayerManager._internal() {
    _initAudioPlayer();
  }

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<VoicePlayerState> stateNotifier = ValueNotifier(const VoicePlayerState());

  StreamSubscription? _posSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _durationSub;

  VoicePlayerState get currentState => stateNotifier.value;

  void _initAudioPlayer() {
    _playerStateSub = _player.onPlayerStateChanged.listen((pState) {
      if (pState == PlayerState.playing) {
        stateNotifier.value = stateNotifier.value.copyWith(status: VoicePlayStatus.playing);
      } else if (pState == PlayerState.paused) {
        stateNotifier.value = stateNotifier.value.copyWith(status: VoicePlayStatus.paused);
      } else if (pState == PlayerState.stopped) {
        stateNotifier.value = stateNotifier.value.copyWith(
          status: VoicePlayStatus.idle,
          positionMs: 0,
        );
      }
    });

    _posSub = _player.onPositionChanged.listen((pos) {
      stateNotifier.value = stateNotifier.value.copyWith(
        positionMs: pos.inMilliseconds,
      );
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      if (dur.inMilliseconds > 0) {
        stateNotifier.value = stateNotifier.value.copyWith(
          totalDurationMs: dur.inMilliseconds,
        );
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      debugPrint('🏁 [VoicePlayerManager] Phát xong tin nhắn: ${stateNotifier.value.activeMessageId}');
      stateNotifier.value = stateNotifier.value.copyWith(
        status: VoicePlayStatus.idle,
        positionMs: 0,
      );
    });
  }

  /// Bật / Tạm dừng phát tin nhắn thoại
  Future<void> togglePlay({
    required String messageId,
    required String mediaUrl,
    int? fallbackDurationMs,
  }) async {
    final current = stateNotifier.value;

    // 1. Nếu đang phát chính tin nhắn này -> Tạm dừng
    if (current.activeMessageId == messageId && current.status == VoicePlayStatus.playing) {
      debugPrint('⏸️ [VoicePlayerManager] Tạm dừng tin: $messageId');
      await _player.pause();
      return;
    }

    // 2. Nếu đang tạm dừng chính tin nhắn này -> Tiếp tục
    if (current.activeMessageId == messageId && current.status == VoicePlayStatus.paused) {
      debugPrint('▶️ [VoicePlayerManager] Tiếp tục phát tin: $messageId');
      await _player.resume();
      return;
    }

    // 3. Nếu là tin nhắn mới (hoặc tin trước đó đang phát) -> Dừng tin cũ, phát tin mới
    debugPrint('🎵 [VoicePlayerManager] Bắt đầu phát tin mới: $messageId (URL: $mediaUrl)');
    await _player.stop();

    stateNotifier.value = VoicePlayerState(
      activeMessageId: messageId,
      status: VoicePlayStatus.loading,
      positionMs: 0,
      totalDurationMs: fallbackDurationMs ?? 0,
      speed: current.speed,
    );

    try {
      Source source;
      if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
        source = UrlSource(mediaUrl);
      } else {
        source = DeviceFileSource(mediaUrl);
      }

      await _player.setPlaybackRate(current.speed);
      await _player.play(source);
    } catch (e) {
      debugPrint('⚠️ [VoicePlayerManager] Lỗi phát audio: $e');
      stateNotifier.value = stateNotifier.value.copyWith(
        status: VoicePlayStatus.error,
        errorMessage: 'Không thể phát âm thanh',
      );
    }
  }

  /// Tua đến vị trí tương ứng (0.0 đến 1.0)
  Future<void> seek(double progress) async {
    final current = stateNotifier.value;
    if (current.activeMessageId == null || current.totalDurationMs <= 0) return;

    final targetMs = (current.totalDurationMs * progress.clamp(0.0, 1.0)).toInt();
    try {
      await _player.seek(Duration(milliseconds: targetMs));
      stateNotifier.value = stateNotifier.value.copyWith(positionMs: targetMs);
    } catch (e) {
      debugPrint('⚠️ [VoicePlayerManager] Lỗi seek: $e');
    }
  }

  /// Chuyển đổi tốc độ phát (1x -> 1.5x -> 2x)
  Future<void> cycleSpeed() async {
    final currentSpeed = stateNotifier.value.speed;
    double nextSpeed = 1.0;
    if (currentSpeed == 1.0) {
      nextSpeed = 1.5;
    } else if (currentSpeed == 1.5) {
      nextSpeed = 2.0;
    } else {
      nextSpeed = 1.0;
    }

    debugPrint('⏩ [VoicePlayerManager] Đổi tốc độ phát: ${nextSpeed}x');
    stateNotifier.value = stateNotifier.value.copyWith(speed: nextSpeed);
    try {
      await _player.setPlaybackRate(nextSpeed);
    } catch (e) {
      debugPrint('⚠️ [VoicePlayerManager] Lỗi đặt tốc độ: $e');
    }
  }

  /// Dừng phát hoàn toàn (khi rời màn hình chat hoặc khi bắt đầu ghi âm mới)
  Future<void> stopAll() async {
    try {
      await _player.stop();
    } catch (_) {}
    stateNotifier.value = stateNotifier.value.copyWith(
      status: VoicePlayStatus.idle,
      positionMs: 0,
    );
  }

  void dispose() {
    _posSub?.cancel();
    _playerStateSub?.cancel();
    _completeSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
  }
}
