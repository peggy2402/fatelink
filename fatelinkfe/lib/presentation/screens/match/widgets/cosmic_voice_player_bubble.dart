import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget phát tin nhắn thoại Voice Note thực tế phong cách iMessage / Telegram
/// Giải quyết vấn đề 3:
/// - Loại bỏ hoàn toàn text dài dòng thừa thãi.
/// - Chỉ có nút Play/Pause tròn, sóng âm động Waveform và thời lượng (00:02).
/// - Có thể bấm Play để chạy thực tế: Đếm giây, sóng âm nhấp nhô sống động, kết thúc tự động về Play.
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
  Timer? _playbackTimer;
  bool _isPlaying = false;
  int _currentSeconds = 0;
  late int _totalDurationSeconds;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Trích xuất thời lượng từ format "00:02" hoặc "0:02"
    _totalDurationSeconds = _extractDurationSeconds(widget.text);
  }

  int _extractDurationSeconds(String text) {
    try {
      final reg = RegExp(r'(\d+):(\d+)');
      final match = reg.firstMatch(text);
      if (match != null) {
        final m = int.tryParse(match.group(1) ?? '0') ?? 0;
        final s = int.tryParse(match.group(2) ?? '2') ?? 2;
        final total = m * 60 + s;
        return total > 0 ? total : 3;
      }
    } catch (_) {}
    return 3; // Mặc định 3s
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _togglePlay() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat(reverse: true);
        _startPlayback();
      } else {
        _animController.stop();
        _playbackTimer?.cancel();
      }
    });
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        if (_currentSeconds < _totalDurationSeconds) {
          _currentSeconds++;
        } else {
          // Kết thúc phát
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
    _playbackTimer?.cancel();
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
                color: isMe ? Colors.white : const Color(0xFF7C3AED),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isMe ? const Color(0xFF7C3AED) : Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Sóng âm Audio Waveform sống động
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
                      children: List.generate(14, (i) {
                        final heights = [
                          8.0, 14.0, 22.0, 16.0, 28.0, 18.0, 24.0,
                          12.0, 20.0, 26.0, 16.0, 22.0, 10.0, 14.0,
                        ];
                        final baseHeight = heights[i % heights.length];
                        final waveHeight = _isPlaying
                            ? (baseHeight * (0.6 + 0.8 * ((_animController.value + (i * 0.1)) % 1.0))).clamp(6.0, 28.0)
                            : baseHeight;

                        final isPlayed = (_currentSeconds / (_totalDurationSeconds > 0 ? _totalDurationSeconds : 1)) >= (i / 14);

                        return Container(
                          width: 3,
                          height: waveHeight,
                          decoration: BoxDecoration(
                            color: isMe
                                ? (isPlayed ? Colors.white : Colors.white.withValues(alpha: 0.45))
                                : (isPlayed ? const Color(0xFF7C3AED) : const Color(0xFFDDD6FE)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 5),

                // Thời lượng hiển thị gọn gàng
                Text(
                  displayDuration,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
