import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? avatarUrl;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.avatarUrl,
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
    // Lấy độ cao vùng an toàn dưới đáy (ví dụ: thanh Home indicator trên iPhone)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: SizedBox(
        height: 100.0 + bottomPadding, // Tính thêm padding đáy vào tổng chiều cao
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Thanh bar màu tối với đường cắt (notch)
            ClipPath(
              clipper: _BottomNavClipper(),
              child: ClipRRect( // Thêm ClipRRect để hiệu ứng blur không bị tràn
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 70.0 + bottomPadding, // Thanh bar cao hơn một chút để bao trọn viền đáy
                    padding: EdgeInsets.only(bottom: bottomPadding), // Đẩy dàn icon lên trên vùng an toàn
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75), // Nền kính mờ sáng
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, 'Trang chủ', Icons.home_filled),
                        _buildNavItem(1, 'Khám phá', Icons.explore_rounded),
                        const SizedBox(width: 80), // Chừa không gian khoét lõm
                        _buildNavItem(2, 'Trò chuyện', Icons.chat_bubble_rounded, hasBadge: true),
                        _buildNavItem(3, 'Tài khoản', Icons.person_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Nút "Ghép đôi" hình trái tim lớn đặt chính giữa
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () {
                  // Sự kiện Ghép đôi
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF3B30), Color(0xFFFF69B4)], // Rose to Pink
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite_rounded,
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

  Widget _buildNavItem(
    int index,
    String label,
    IconData iconData, {
    bool hasBadge = false,
  }) {
    final isSelected = widget.currentIndex == index;
    final color = isSelected ? const Color(0xFF00B8D4) : Colors.blueGrey.shade400; // Màu Cyan đậm khi chọn, xám xanh khi không chọn

    return SizedBox(
      width: 60,
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
              transformAlignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(iconData, color: color, size: 26),
                  if (hasBadge)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      Rect.fromCircle(center: Offset(size.width / 2, 0), radius: 38), // Notch radius
    );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
