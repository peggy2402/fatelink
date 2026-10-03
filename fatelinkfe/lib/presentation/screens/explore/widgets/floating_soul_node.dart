import 'package:flutter/material.dart';
import '../../../../core/utils/anonymous_avatar_helper.dart';
import '../../../../data/models/match_user.dart';

/// Node tâm hồn lơ lửng trên vòm Radar (Floating Orbit Node)
class FloatingSoulNode extends StatefulWidget {
  final MatchUser user;
  final Offset position;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const FloatingSoulNode({
    super.key,
    required this.user,
    required this.position,
    required this.isSelected,
    required this.index,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  State<FloatingSoulNode> createState() => _FloatingSoulNodeState();
}

class _FloatingSoulNodeState extends State<FloatingSoulNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2400 + (widget.index % 3) * 400),
    );

    _floatAnim = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) _floatController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isSelected = widget.isSelected;

    return Positioned(
      left: widget.position.dx - 30,
      top: widget.position.dy - 30,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Hào quang nở rực rỡ khi được chọn (Glow Halo)
                  if (isSelected)
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                  // Avatar chính
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFF00E5FF)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected
                                  ? const Color(0xFFEC4899)
                                  : const Color(0xFF6366F1))
                              .withValues(alpha: 0.35),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnonymousAvatarHelper.buildAvatar(
                      user: user,
                      size: isSelected ? 50 : 44,
                      showLockBadge: false,
                    ),
                  ),

                  // Huy hiệu Emoji cảm xúc (Góc trên bên phải)
                  if (user.moodIcon != null && user.moodIcon!.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          user.moodIcon!,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),

                  // Huy hiệu % tương hợp (Góc dưới bên phải)
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${user.compatibilityScore}%',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Nhãn tên bí danh mờ nhẹ dưới node
              Container(
                constraints: const BoxConstraints(maxWidth: 78),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  user.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 10.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
