import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? avatarUrl;
  final VoidCallback? onHeartTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.avatarUrl,
    this.onHeartTap,
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        const SizedBox(width: 80), // Chừa không gian khoét lõm nút tim
                        _buildNavItem(
                          index: 2,
                          label: 'Trò chuyện',
                          unselectedIcon: CupertinoIcons.bubble_left_bubble_right,
                          selectedIcon: CupertinoIcons.bubble_left_bubble_right_fill,
                          hasBadge: true,
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
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData unselectedIcon,
    required IconData selectedIcon,
    bool hasBadge = false,
    bool isProfile = false,
  }) {
    final isSelected = widget.currentIndex == index;
    // Màu xanh nhận diện thương hiệu Meyu khi chọn, màu Slate xám tinh tế khi chưa chọn
    final activeColor = const Color(0xFF0066FF);
    final inactiveColor = const Color(0xFF94A3B8);
    final color = isSelected ? activeColor : inactiveColor;

    return SizedBox(
      width: 64,
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                        child: Image.network(
                          widget.avatarUrl!,
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

                  // Chấm đỏ thông báo tin nhắn chưa đọc
                  if (hasBadge)
                    Positioned(
                      right: -3,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const SizedBox(width: 4, height: 4),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
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
