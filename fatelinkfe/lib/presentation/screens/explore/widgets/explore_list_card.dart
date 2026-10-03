import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/anonymous_avatar_helper.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../data/models/match_user.dart';
import '../../../widgets/cosmic_pulse_received_modal.dart';

/// Thẻ Danh Thiếp Tâm Hồn (ExploreListCard):
/// - Tối ưu hóa hiệu năng render 120 FPS: Tuyệt đối không dùng BackdropFilter
/// - Nhấn vào BẤT KỲ ĐÂU trên thẻ đều mở trang chi tiết hồ sơ
/// - Thiết kế Cosmic gọn gàng, tinh tế, thoáng đãng
/// - Đầy đủ nút tương tác: Gửi sóng 432Hz ⚡, Nhắn tin 💬, Thả tim 💖
class ExploreListCard extends StatefulWidget {
  final MatchUser user;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const ExploreListCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onChat,
  });

  @override
  State<ExploreListCard> createState() => _ExploreListCardState();
}

class _ExploreListCardState extends State<ExploreListCard> {
  bool _isLiked = false;
  bool _isPinged = false;

  void _handlePing() {
    if (_isPinged) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPinged = true);
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

  void _handleLike() {
    HapticFeedback.lightImpact();
    setState(() => _isLiked = !_isLiked);
    if (_isLiked) {
      ToastUtil.showSuccess(
        context,
        'Đã gửi tương hợp tâm hồn đến ${widget.user.displayName}!',
      );
    }
  }

  String _resolveDistance(MatchUser user) {
    if (user.distanceKm != null) {
      return '${user.distanceKm!.toStringAsFixed(1)} km';
    }
    final seed = user.id.isNotEmpty ? user.id.hashCode : 42;
    final dist = ((seed.abs() % 45) / 10.0 + 0.6).toStringAsFixed(1);
    return '$dist km';
  }

  List<String> _resolveTags(MatchUser user) {
    if (user.tags != null && user.tags!.isNotEmpty) {
      return user.tags!;
    }
    switch (user.emotion.toLowerCase()) {
      case 'bình yên':
        return ['#ĐọcSách', '#CàPhê', '#BìnhYên'];
      case 'lãng mạn':
        return ['#NhạcIndie', '#ĐêmMưa', '#LãngMạn'];
      case 'bí ẩn':
        return ['#ThiênVăn', '#DeepTalk', '#BíẨn'];
      case 'chill':
        return ['#LofiChill', '#Podcast', '#TâmSự'];
      default:
        return ['#ĐồngĐiệu', '#TầnSốSóng', '#KếtNối'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final distance = _resolveDistance(user);
    final tags = _resolveTags(user);
    final bio = (user.bio != null && user.bio!.trim().isNotEmpty)
        ? user.bio!.trim()
        : 'Muốn tìm người cùng đi dạo chuyện trò những đêm muộn...';

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Hàng Header: Avatar + Tên & Huy hiệu + Match % Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar với viền hào quang neon
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                          ),
                        ),
                        child: AnonymousAvatarHelper.buildAvatar(
                          user: user,
                          size: 48,
                          showLockBadge: true,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tên bí danh + Giới tính/Tuổi + Khoảng cách
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
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Chip Giới tính & Tuổi
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: user.resolvedGender == 'female'
                                        ? const Color(0xFFFDF2F8)
                                        : const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
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
                                      fontSize: 10,
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

                            // Dòng trạng thái phát sóng & khoảng cách
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$distance • ',
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.emotion,
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Huy hiệu Hòa hợp %
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
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
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const Text(
                              'Hòa hợp',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 9.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 2. Lời thì thầm tâm hồn (Bio)
                  Text(
                    bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF475569),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Tags cảm xúc nhỏ gọn
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // 4. Hàng nút tương tác nhanh theo Cơ chế 1
                  Row(
                    children: [
                      if (user.isMutualFollow)
                        // Khi đã cộng hưởng: Nút Trò chuyện
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onChat();
                            },
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Trò chuyện ngay',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 12,
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
                        // Khi chưa cộng hưởng: Nút Gửi sóng 432Hz duy nhất
                        Expanded(
                          child: GestureDetector(
                            onTap: _handlePing,
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: _isPinged
                                    ? const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                                      ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isPinged
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEC4899))
                                        .withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
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
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isPinged ? 'Đã gửi sóng' : 'Gửi sóng 432Hz',
                                    style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),

                      // Nút Thả Tim
                      GestureDetector(
                        onTap: _handleLike,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _isLiked
                                ? const Color(0xFFFDF2F8)
                                : const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isLiked
                                  ? const Color(0xFFF472B6)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: _isLiked
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Nút Mũi tên xem chi tiết
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onTap();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
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
