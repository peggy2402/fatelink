import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/responsive/responsive.dart';
import '../../core/services/image_picker_service.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? avatarUrl;
  final VoidCallback? onHeartTap;
  final int unreadChatCount;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.avatarUrl,
    this.onHeartTap,
    this.unreadChatCount = 0,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuint,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: ResponsiveCenter(
        maxWidth: 580,
        child: SizedBox(
          height: 100.0 + bottomPadding,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
            // Thanh bar kính mờ (Glassmorphism) với đường cong khoét nút tim
            ClipPath(
              clipper: _BottomNavClipper(),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    height: 70.0 + bottomPadding,
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildNavItem(
                          index: 0,
                          label: 'Trang chủ',
                          unselectedIcon: CupertinoIcons.house,
                          selectedIcon: CupertinoIcons.house_fill,
                        ),
                        _buildNavItem(
                          index: 1,
                          label: 'Khám phá',
                          unselectedIcon: CupertinoIcons.compass,
                          selectedIcon: CupertinoIcons.compass_fill,
                        ),
                        const SizedBox(width: 72), // Chừa không gian khoét lõm nút tim
                        _buildNavItem(
                          index: 2,
                          label: 'Trò chuyện',
                          unselectedIcon: CupertinoIcons.bubble_left_bubble_right,
                          selectedIcon: CupertinoIcons.bubble_left_bubble_right_fill,
                          hasBadge: widget.unreadChatCount > 0,
                          unreadCount: widget.unreadChatCount,
                        ),
                        _buildNavItem(
                          index: 3,
                          label: 'Tài khoản',
                          unselectedIcon: CupertinoIcons.person_crop_circle,
                          selectedIcon: CupertinoIcons.person_crop_circle_fill,
                          isProfile: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Nút "Ghép đôi / Radar" hình trái tim lớn đặt chính giữa
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () {
                  widget.onHeartTap?.call();
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2A6D), Color(0xFFFF5E97)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2A6D).withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.heart_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData unselectedIcon,
    required IconData selectedIcon,
    bool hasBadge = false,
    int unreadCount = 0,
    bool isProfile = false,
  }) {
    final isSelected = widget.currentIndex == index;
    // Màu xanh nhận diện thương hiệu Meyu khi chọn, màu Slate xám tinh tế khi chưa chọn
    final activeColor = const Color(0xFF0066FF);
    final inactiveColor = const Color(0xFF94A3B8);
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              transform: Matrix4.diagonal3Values(
                isSelected ? 1.15 : 1.0,
                isSelected ? 1.15 : 1.0,
                1.0,
              ),
              transformAlignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (isProfile && widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image(
                          image: ImagePickerService.getImageProvider(widget.avatarUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            isSelected ? selectedIcon : unselectedIcon,
                            color: color,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  else
                    Icon(
                      isSelected ? selectedIcon : unselectedIcon,
                      color: color,
                      size: 24,
                    ),

                  // Huy hiệu số đếm thông báo tin nhắn chưa đọc (5+ nếu > 5)
                  if (hasBadge && unreadCount > 0)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF2A6D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A6D).withValues(alpha: 0.45),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 5 ? '5+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            // Thanh chỉ báo active siêu mảnh, thanh lịch
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 3),
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Clipper tạo đường cắt lún ôm trọn nút giữa
class _BottomNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return const CircularNotchedRectangle().getOuterPath(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Rect.fromCircle(center: Offset(size.width / 2, 0), radius: 38),
    );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
