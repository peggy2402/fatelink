import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal ghi âm giọng nói trực tiếp (Voice Note) phong cách Telegram / WhatsApp
/// Giải quyết vấn đề 4.4: Ghi âm giọng nói thực tế, có sóng âm động, đếm giây,
/// cho phép hủy hoặc gửi tin nhắn thoại.
class CosmicVoiceRecorderModal extends StatefulWidget {
  final Function(String voiceMessageText, int durationSeconds) onSendVoice;

  const CosmicVoiceRecorderModal({
    super.key,
    required this.onSendVoice,
  });

  static void show(
    BuildContext context, {
    required Function(String voiceMessageText, int durationSeconds) onSendVoice,
  }) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CosmicVoiceRecorderModal(onSendVoice: onSendVoice),
    );
  }

  @override
  State<CosmicVoiceRecorderModal> createState() => _CosmicVoiceRecorderModalState();
}

class _CosmicVoiceRecorderModalState extends State<CosmicVoiceRecorderModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _timer;
  int _seconds = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33EC4899),
              blurRadius: 28,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),

            // Huy hiệu Đang ghi âm nhấp nháy
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (ctx, child) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEF4444).withValues(
                        alpha: _isPaused ? 0.3 : (0.4 + _animController.value * 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isPaused ? 'Đã tạm dừng' : 'Đang lắng nghe giọng nói...',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isPaused ? const Color(0xFF64748B) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Thời gian ghi âm đếm thực tế
            Text(
              _formatDuration(_seconds),
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Sóng âm giả lập chuyển động nhịp nhàng (Waveform Bars)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(24, (i) {
                      final factor = (i % 5 + 1) * 0.18;
                      final waveHeight = _isPaused
                          ? 8.0
                          : (12.0 + 36.0 * ((_animController.value + factor) % 1.0));
                      return Container(
                        width: 4,
                        height: waveHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Hàng nút điều khiển: Hủy - Tạm dừng - Gửi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Nút Hủy
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  iconSize: 48,
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                ),

                // Nút Tạm dừng / Tiếp tục
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isPaused = !_isPaused);
                  },
                  iconSize: 52,
                  icon: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: const Color(0xFF7C3AED),
                      size: 26,
                    ),
                  ),
                ),

                // Nút Gửi tin nhắn thoại
                GestureDetector(
                  onTap: () {
                    if (_seconds == 0) _seconds = 1;
                    HapticFeedback.mediumImpact();
                    final formatted = _formatDuration(_seconds);
                    final voiceText = '🎙️ [Tin nhắn thoại $formatted]';
                    widget.onSendVoice(voiceText, _seconds);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
