import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../data/models/match_user.dart';
import '../../../../core/responsive/responsive.dart';

class SoulMatchCard extends StatefulWidget {
  final MatchUser user;
  final VoidCallback? onTap;
  final VoidCallback? onChat;
  final VoidCallback? onLike;

  const SoulMatchCard({
    super.key,
    required this.user,
    this.onTap,
    this.onChat,
    this.onLike,
  });

  @override
  State<SoulMatchCard> createState() => _SoulMatchCardState();
}

class _SoulMatchCardState extends State<SoulMatchCard> {
  bool _isLiked = false;

  // Giả lập tag cảm xúc phong phú dựa trên tên/emotion
  List<String> _resolveTags(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'cô đơn':
        return ['#NhạcIndie', '#ĐêmMuộn', '#DeepTalk'];
      case 'phấn khích':
        return ['#DuLịch', '#Startup', '#NăngLượng'];
      case 'bình yên':
        return ['#ĐọcSách', '#CàPhê', '#ThiênNhiên'];
      case 'áp lực':
        return ['#LắngNghe', '#ChiaSẻ', '#TâmSự'];
      default:
        return ['#KếtNốiSâu', '#TầnSốTươngĐồng', '#FayeMatch'];
    }
  }

  String _resolveDistance(String id) {
    final dist = ((id.hashCode.abs() % 45) / 10.0 + 0.5).toStringAsFixed(1);
    return '$dist km';
  }

  @override
  Widget build(BuildContext context) {
    final tags = (widget.user.tags != null && widget.user.tags!.isNotEmpty)
        ? widget.user.tags!
        : _resolveTags(widget.user.emotion);
    final distance = widget.user.distanceKm != null
        ? '${widget.user.distanceKm} km'
        : _resolveDistance(widget.user.id);
    final avatarUrl = widget.user.avatar ??
        'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(widget.user.name)}&backgroundColor=e0e7ff';

    return ResponsiveCenter(
      maxWidth: 580,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header của Card: Avatar + Tên + Match % Badge ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar với viền phát sáng nhẹ
                      Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFFE0E7FF),
                              child: Icon(Icons.person_rounded, color: Color(0xFF6366F1), size: 28),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Thông tin: Tên, khoảng cách
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 15),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 3),
                                      child: Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 13),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '$distance • ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Đang phát tần số',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Match Score % Gradient Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.user.compatibilityScore}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // --- Tần số cảm xúc (Sound Wave) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.graphic_eq_rounded, color: Color(0xFF8B5CF6), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Tần số: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blueGrey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: '${widget.user.moodIcon != null ? "${widget.user.moodIcon} " : ""}${widget.user.emotion}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- Emotional Tags Chips (#NhạcIndie, #DeepTalk...) ---
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // --- Bottom Action Buttons ---
                  Row(
                    children: [
                      // Nút Thả tim (Like)
                      InkWell(
                        onTap: () {
                          setState(() => _isLiked = !_isLiked);
                          widget.onLike?.call();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isLiked
                                ? const Color(0xFFFDE8E8)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isLiked
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Icon(
                            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Nút Nhắn tin nhanh (Quick Message)
                      Expanded(
                        child: InkWell(
                          onTap: widget.onChat,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Gửi tin nhắn',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
    ),
  );
}
}
