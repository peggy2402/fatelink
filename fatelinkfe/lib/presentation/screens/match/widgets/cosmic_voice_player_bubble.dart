import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Widget phát tin nhắn thoại Voice Note thực tế phong cách iMessage / Telegram
/// - Tự động phát âm thanh ra loa bằng `audioplayers`
/// - Hỗ trợ cả URL Cloudinary CDN và file cục bộ
/// - Hiển thị Waveform sóng âm nhấp nhô và thời lượng thực tế
class CosmicVoicePlayerBubble extends StatefulWidget {
  final String text;
  final bool isSentByMe;

  const CosmicVoicePlayerBubble({
    super.key,
    required this.text,
    required this.isSentByMe,
  });

  @override
  State<CosmicVoicePlayerBubble> createState() => _CosmicVoicePlayerBubbleState();
}

class _CosmicVoicePlayerBubbleState extends State<CosmicVoicePlayerBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;
  Timer? _fallbackTimer;

  bool _isPlaying = false;
  int _currentSeconds = 0;
  late int _totalDurationSeconds;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _audioUrl = _extractAudioUrl(widget.text);
    _totalDurationSeconds = _extractDurationSeconds(widget.text);

    _listenAudioPlayer();
  }

  void _listenAudioPlayer() {
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final playing = state == PlayerState.playing;
      setState(() => _isPlaying = playing);
      if (playing) {
        _animController.repeat(reverse: true);
      } else {
        _animController.stop();
      }
    });

    _posSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() {
        _currentSeconds = pos.inSeconds;
      });
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _currentSeconds = 0;
      });
      _animController.stop();
    });
  }

  String? _extractAudioUrl(String text) {
    // Format 1: [voice:https://res.cloudinary.com/...]
    final reg = RegExp(r'\[voice:(https?://[^\|\]]+)');
    final match = reg.firstMatch(text);
    if (match != null) return match.group(1);

    // Format 2: Đường dẫn file cục bộ [voice:/data/user/...]
    final regFile = RegExp(r'\[voice:(/[^\|\]]+)');
    final matchFile = regFile.firstMatch(text);
    if (matchFile != null) return matchFile.group(1);

    // Format 3: URL trực tiếp
    final regDirect = RegExp(r'(https?://[^\s]+\.(m4a|aac|mp3|ogg|wav))');
    final matchDirect = regDirect.firstMatch(text);
    if (matchDirect != null) return matchDirect.group(1);

    return null;
  }

  int _extractDurationSeconds(String text) {
    try {
      final regDur = RegExp(r'duration:(\d+)');
      final matchDur = regDur.firstMatch(text);
      if (matchDur != null) {
        final sec = int.tryParse(matchDur.group(1) ?? '3') ?? 3;
        if (sec > 0) return sec;
      }

      final reg = RegExp(r'(\d+):(\d+)');
      final match = reg.firstMatch(text);
      if (match != null) {
        final m = int.tryParse(match.group(1) ?? '0') ?? 0;
        final s = int.tryParse(match.group(2) ?? '3') ?? 3;
        final total = m * 60 + s;
        return total > 0 ? total : 3;
      }
    } catch (_) {}
    return 3;
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    HapticFeedback.mediumImpact();

    if (_isPlaying) {
      await _audioPlayer.pause();
      _fallbackTimer?.cancel();
      setState(() => _isPlaying = false);
      _animController.stop();
      return;
    }

    if (_audioUrl != null && _audioUrl!.isNotEmpty) {
      try {
        if (_audioUrl!.startsWith('http://') || _audioUrl!.startsWith('https://')) {
          await _audioPlayer.play(UrlSource(_audioUrl!));
        } else {
          await _audioPlayer.play(DeviceFileSource(_audioUrl!));
        }
      } catch (e) {
        debugPrint('⚠️ [CosmicVoicePlayerBubble] Lỗi play audio: $e');
        _startFallbackTimer();
      }
    } else {
      _startFallbackTimer();
    }
  }

  void _startFallbackTimer() {
    setState(() => _isPlaying = true);
    _animController.repeat(reverse: true);
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        if (_currentSeconds < _totalDurationSeconds) {
          _currentSeconds++;
        } else {
          _isPlaying = false;
          _currentSeconds = 0;
          _animController.stop();
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isSentByMe;
    final displayDuration = _isPlaying
        ? _formatDuration(_currentSeconds)
        : _formatDuration(_totalDurationSeconds);

    return Container(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút Play / Pause
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isMe ? Colors.white : const Color(0xFF6366F1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? Colors.black : const Color(0xFF6366F1))
                        .withValues(alpha: isMe ? 0.08 : 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isMe ? const Color(0xFF6366F1) : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Sóng âm giả lập di chuyển nhịp nhàng khi phát
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(14, (index) {
                        final factor = (index % 4 + 1) * 0.22;
                        final barHeight = _isPlaying
                            ? (6.0 + 16.0 * ((_animController.value + factor) % 1.0))
                            : (6.0 + (index % 3) * 4.0);

                        return Container(
                          width: 3,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF6366F1).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 4),

                // Hiển thị thời lượng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayDuration,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    if (_audioUrl != null)
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 11,
                        color: isMe ? Colors.white70 : const Color(0xFF10B981),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
