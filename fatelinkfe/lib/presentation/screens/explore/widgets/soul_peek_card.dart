import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/anonymous_avatar_helper.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../data/models/match_user.dart';
import '../../../widgets/cosmic_pulse_received_modal.dart';

/// Thẻ Kính Mờ "Soul Peek Sheet" hiển thị chi tiết tâm hồn được chọn trên Radar:
/// - Avatar 3D ẩn danh với huy hiệu cảm xúc
/// - Tên bí danh, Giới tính, Tuổi, Khoảng cách km
/// - Điểm tương hợp % nổi bật
/// - 3 Nút hành động nhanh: Bắn tín hiệu sóng ⚡, Trò chuyện 💬, Xem hồ sơ 👤
class SoulPeekCard extends StatefulWidget {
  final MatchUser user;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onChat;
  final VoidCallback onViewProfile;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  const SoulPeekCard({
    super.key,
    required this.user,
    required this.currentIndex,
    required this.totalCount,
    required this.onChat,
    required this.onViewProfile,
    this.onNext,
    this.onPrev,
  });

  @override
  State<SoulPeekCard> createState() => _SoulPeekCardState();
}

class _SoulPeekCardState extends State<SoulPeekCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pingAnimController;
  bool _isPinged = false;

  @override
  void initState() {
    super.initState();
    _pingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant SoulPeekCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _isPinged = false;
      _pingAnimController.reset();
    }
  }

  @override
  void dispose() {
    _pingAnimController.dispose();
    super.dispose();
  }

  void _handleSendPing() {
    if (_isPinged) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPinged = true);
    _pingAnimController.forward(from: 0.0);

    ToastUtil.showSuccess(
      context,
      'Đã phát xung sóng 432Hz đến ${widget.user.displayName}!',
    );

    // Mô phỏng màn hình phía đối phương sau 1.2s để người dùng xem trực quan
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        CosmicPulseReceivedModal.show(context, sender: widget.user);
      }
    });
  }

  String _resolveDistance(MatchUser user) {
    if (user.distanceKm != null) {
      return '${user.distanceKm!.toStringAsFixed(1)} km gần bạn';
    }
    final seed = user.id.isNotEmpty ? user.id.hashCode : 42;
    final dist = ((seed.abs() % 45) / 10.0 + 0.6).toStringAsFixed(1);
    return '$dist km gần bạn';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final distanceText = _resolveDistance(user);
    final bioText = (user.bio != null && user.bio!.trim().isNotEmpty)
        ? user.bio!.trim()
        : 'Muốn tìm người cùng đi dạo chuyện trò những đêm muộn...';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onViewProfile();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.95),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Avatar + Tên + Khoảng cách + % Tương hợp
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar với hào quang viền phát sáng
                    GestureDetector(
                      onTap: widget.onViewProfile,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnonymousAvatarHelper.buildAvatar(
                          user: user,
                          size: 50,
                          showLockBadge: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tên + Giới tính + Tuổi + Khoảng cách
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Huy hiệu Giới tính & Tuổi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: user.resolvedGender == 'female'
                                      ? const Color(0xFFFDF2F8)
                                      : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: user.resolvedGender == 'female'
                                        ? const Color(0xFFF472B6)
                                        : const Color(0xFF818CF8),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${user.genderLabel} • ${user.resolvedAge}',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: user.resolvedGender == 'female'
                                        ? const Color(0xFFDB2777)
                                        : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Khoảng cách & Tần số
                          Row(
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${user.emotion}',
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Badge Điểm tương hợp
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${user.compatibilityScore}%',
                            style: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const Text(
                            'Hòa hợp',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Lời thì thầm tâm hồn (Bio)
                Text(
                  bioText,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    color: Color(0xFF334155),
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // 3. Hàng nút hành động nhanh
                Row(
                  children: [
                    if (user.isMutualFollow)
                      // Khi đã cộng hưởng: Nút Trò chuyện ngay
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onChat();
                          },
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Trò chuyện ngay',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      // Khi chưa cộng hưởng: Nút Gửi sóng 432Hz độc tôn
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleSendPing,
                          child: AnimatedBuilder(
                            animation: _pingAnimController,
                            builder: (context, child) {
                              final scale = 1.0 - _pingAnimController.value * 0.08;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: _isPinged
                                    ? const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isPinged
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEC4899))
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isPinged
                                        ? Icons.check_circle_rounded
                                        : Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isPinged ? 'Đã gửi sóng' : 'Gửi sóng 432Hz',
                                    style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),

                    // Nút Xem Hồ Sơ Chi Tiết
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onViewProfile();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

