import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/voice_player_manager.dart';
import '../../../../data/models/chat_message.dart';

/// Widget phát tin nhắn thoại Voice Note phong cách Telegram chuẩn mực
/// - Khung hình và kích thước ĐỨNG YÊN HOÀN TOÀN (Zero-jitter / Không rung lắc)
/// - Waveform 40 cột biên độ thực tế, tô màu tiến trình phát chuẩn xác
/// - Tua (Seek) bằng cử chỉ chạm/vuốt trên sóng âm
/// - Nút đổi tốc độ phát (1x, 1.5x, 2x)
/// - Sử dụng VoicePlayerManager singleton, chỉ 1 âm thanh phát tại một thời điểm
class CosmicVoicePlayerBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSentByMe;
  final VoidCallback? onRetrySend;

  const CosmicVoicePlayerBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.onRetrySend,
  });

  String _formatDuration(int ms) {
    final totalSecs = (ms / 1000).ceil();
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = message.effectiveMediaUrl;
    final totalDurationMs = message.effectiveDurationMs;
    final waveform = message.effectiveWaveform;
    final messageId = message.id;

    // Chiều rộng cố định theo thời lượng (180dp - 240dp)
    final bubbleWidth = (185.0 + (totalDurationMs / 1000) * 1.5).clamp(185.0, 240.0);

    return Container(
      width: bubbleWidth,
      height: 52, // Chiều cao CỐ ĐỊNH tuyệt đối -> Không bao giờ bị rung lắc
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ValueListenableBuilder<VoicePlayerState>(
        valueListenable: VoicePlayerManager().stateNotifier,
        builder: (context, playerState, _) {
          final isThisPlaying = playerState.activeMessageId == messageId &&
              playerState.status == VoicePlayStatus.playing;
          final isThisLoading = playerState.activeMessageId == messageId &&
              playerState.status == VoicePlayStatus.loading;
          final isThisPaused = playerState.activeMessageId == messageId &&
              playerState.status == VoicePlayStatus.paused;
          final isThisError = playerState.activeMessageId == messageId &&
              playerState.status == VoicePlayStatus.error;

          // Tiến trình phát (0.0 đến 1.0)
          double progress = 0.0;
          int displayPositionMs = totalDurationMs;

          if (playerState.activeMessageId == messageId) {
            final effectiveTotal = playerState.totalDurationMs > 0
                ? playerState.totalDurationMs
                : totalDurationMs;
            if (effectiveTotal > 0) {
              progress = (playerState.positionMs / effectiveTotal).clamp(0.0, 1.0);
            }
            displayPositionMs = (isThisPlaying || isThisPaused)
                ? playerState.positionMs
                : totalDurationMs;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. NÚT PLAY / PAUSE / SPINNER / ERROR (38dp cố định)
              _buildPlayButton(
                context: context,
                isThisPlaying: isThisPlaying,
                isThisLoading: isThisLoading,
                isThisError: isThisError,
                mediaUrl: mediaUrl,
                totalDurationMs: totalDurationMs,
              ),

              const SizedBox(width: 8),

              // 2. KHU VỰC SÓNG ÂM VÀ THỜI LƯỢNG
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Waveform Custom Painter (Chiều cao khung 22dp cố định)
                    SizedBox(
                      height: 22,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          if (mediaUrl == null || mediaUrl.isEmpty) return;
                          final box = context.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final localX = details.localPosition.dx;
                            // Tính tỷ lệ vị trí bấm trên waveform
                            final ratio = (localX / (bubbleWidth - 54)).clamp(0.0, 1.0);
                            HapticFeedback.selectionClick();
                            VoicePlayerManager().seek(ratio);
                          }
                        },
                        onHorizontalDragUpdate: (details) {
                          if (mediaUrl == null || mediaUrl.isEmpty) return;
                          final box = context.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final localX = details.localPosition.dx;
                            final ratio = (localX / (bubbleWidth - 54)).clamp(0.0, 1.0);
                            VoicePlayerManager().seek(ratio);
                          }
                        },
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _TelegramWaveformPainter(
                              waveform: waveform,
                              progress: progress,
                              isSentByMe: isSentByMe,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Hàng phụ: Thời lượng bên trái, Tốc độ (1x, 1.5x, 2x) bên phải
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Thời lượng
                        Text(
                          _formatDuration(displayPositionMs),
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isSentByMe
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF64748B),
                          ),
                        ),

                        // Chip Tốc độ phát (Chỉ hiện khi đang phát chính tin này)
                        if (isThisPlaying || isThisPaused)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              VoicePlayerManager().cycleSpeed();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSentByMe
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${playerState.speed == 1.0 ? '1' : playerState.speed.toString()}x',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSentByMe ? Colors.white : const Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                          )
                        else if (message.isSending)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white70,
                            ),
                          )
                        else if (message.isSendError)
                          GestureDetector(
                            onTap: onRetrySend,
                            child: const Row(
                              children: [
                                Icon(Icons.refresh_rounded, size: 12, color: Color(0xFFEF4444)),
                                SizedBox(width: 2),
                                Text(
                                  'Gửi lại',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 9.5,
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayButton({
    required BuildContext context,
    required bool isThisPlaying,
    required bool isThisLoading,
    required bool isThisError,
    required String? mediaUrl,
    required int totalDurationMs,
  }) {
    // Trạng thái Lỗi gửi hoặc Lỗi phát
    if (message.isSendError || isThisError) {
      return GestureDetector(
        onTap: () {
          if (message.isSendError) {
            onRetrySend?.call();
          } else if (mediaUrl != null && mediaUrl.isNotEmpty) {
            VoicePlayerManager().togglePlay(
              messageId: message.id,
              mediaUrl: mediaUrl,
              fallbackDurationMs: totalDurationMs,
            );
          }
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    // Trạng thái Đang upload nền
    if (message.isSending || isThisLoading) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSentByMe ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isSentByMe ? Colors.white : const Color(0xFF7C3AED),
            ),
          ),
        ),
      );
    }

    // Trạng thái Bình thường (Play / Pause)
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (mediaUrl == null || mediaUrl.isEmpty) {
          debugPrint('⚠️ [CosmicVoicePlayerBubble] URL âm thanh rỗng');
          return;
        }

        VoicePlayerManager().togglePlay(
          messageId: message.id,
          mediaUrl: mediaUrl,
          fallbackDurationMs: totalDurationMs,
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSentByMe ? Colors.white : const Color(0xFF7C3AED),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isSentByMe ? Colors.black : const Color(0xFF7C3AED))
                  .withValues(alpha: isSentByMe ? 0.08 : 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: isSentByMe ? const Color(0xFF7C3AED) : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Painter vẽ 40 thanh sóng âm cố định (Waveform Painter)
/// - Chiều cao từng cột lấy từ mảng waveform 0 - 31 (chuẩn hóa trên max 22dp)
/// - Không bao giờ thay đổi kích thước hay làm rung bong bóng
/// - Tô màu tiến trình đậm (đã phát) và nhạt (chưa phát)
class _TelegramWaveformPainter extends CustomPainter {
  final List<int> waveform;
  final double progress; // 0.0 đến 1.0
  final bool isSentByMe;

  _TelegramWaveformPainter({
    required this.waveform,
    required this.progress,
    required this.isSentByMe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final barCount = waveform.length;
    final totalSpacing = size.width;
    final barWidth = 2.2;
    final spacing = (totalSpacing - (barCount * barWidth)) / (barCount - 1);

    final playedPaint = Paint()
      ..color = isSentByMe ? Colors.white : const Color(0xFF7C3AED)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final unplayedPaint = Paint()
      ..color = isSentByMe
          ? Colors.white.withValues(alpha: 0.38)
          : const Color(0xFF94A3B8).withValues(alpha: 0.5)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final playedBarsCount = (barCount * progress).floor();

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing) + (barWidth / 2);
      // Scale giá trị 0..31 thành chiều cao 3.0 .. size.height
      final rawHeight = waveform[i];
      final heightRatio = (rawHeight / 31.0).clamp(0.12, 1.0);
      final barHeight = max(3.5, size.height * heightRatio);

      final yTop = (size.height - barHeight) / 2;
      final yBottom = yTop + barHeight;

      final paint = (i < playedBarsCount) ? playedPaint : unplayedPaint;
      canvas.drawLine(Offset(x, yTop), Offset(x, yBottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TelegramWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveform != waveform ||
        oldDelegate.isSentByMe != isSentByMe;
  }
}
