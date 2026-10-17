import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal Popup Vũ Trụ khi Faye AI đã thấu hiểu người dùng (CosmicMatchReadyModal):
/// - BackdropFilter Blur nền mờ cao cấp
/// - Avatar Faye AI với quầng sáng Cosmic Tri-Color Glow
/// - Huy hiệu thấu cảm bước sóng tâm hồn
/// - Nút CTA chuẩn Rule 7 (triệt tiêu 100% vệt vuông mờ) dẫn sang màn hình khám phá
class CosmicMatchReadyModal extends StatelessWidget {
  final String message;
  final VoidCallback onExploreMatches;
  final VoidCallback? onContinueChat;

  const CosmicMatchReadyModal({
    super.key,
    required this.message,
    required this.onExploreMatches,
    this.onContinueChat,
  });

  /// Phương thức hiển thị modal tiện lợi từ bất kỳ đâu
  static Future<void> show(
    BuildContext context, {
    required String message,
    required VoidCallback onExploreMatches,
    VoidCallback? onContinueChat,
  }) {
    HapticFeedback.heavyImpact();

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CosmicMatchReadyModal',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => CosmicMatchReadyModal(
        message: message,
        onExploreMatches: onExploreMatches,
        onContinueChat: onContinueChat,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMessage = message.isNotEmpty
        ? message
        : 'Faye đã cảm nhận được những rung động và chiều sâu cảm xúc của bạn. Đang sẵn sàng mở ra kết nối định mệnh...';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Họa tiết ánh sáng Cosmic ở góc trên
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEC4899).withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -40,
                  left: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Nội dung chính
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar Faye AI với Cosmic Tri-Color Glow
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEC4899),
                              Color(0xFF8B5CF6),
                              Color(0xFF00E5FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
                          radius: 36,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Huy hiệu Thấu cảm
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withValues(alpha: 0.12),
                              const Color(0xFFEC4899).withValues(alpha: 0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'ĐÃ ĐỒNG BỘ TẦN SỐ TÂM HỒN',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                color: Color(0xFF6366F1),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tiêu đề
                      const Text(
                        'Faye Đã Hiểu Bạn!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Lời nhắn thấu cảm của Faye
                      Text(
                        displayMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: Color(0xFF475569),
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút CTA 1: Khám phá người đồng điệu (Chuẩn Rule 7)
                      Container(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)], // Fate Signature Gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.38),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                              onExploreMatches();
                            },
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.radar_rounded, color: Colors.white, size: 19),
                                  SizedBox(width: 8),
                                  Text(
                                    'Khám phá người đồng điệu ngay',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Nút Phụ: Tiếp tục trò chuyện
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onContinueChat?.call();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                        child: const Text(
                          'Tiếp tục tâm sự với Faye',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
