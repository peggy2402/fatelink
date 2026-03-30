import 'package:flutter/material.dart';
import 'dart:ui';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, 'Home', 0),
              _buildNavItem(Icons.chat_bubble_outline, 'Chat', 1),
              _buildNavItem(Icons.favorite_border, 'Matches', 2),
              _buildNavItem(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? Colors.white
        : Colors.white54; // Đổi màu highlight thành trắng

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hiệu ứng Shadow phát sáng khi được chọn
          Container(
            decoration: isSelected
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4), // Glow trắng
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                    shape: BoxShape.circle,
                  )
                : null,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8), // Padding bottom for SafeArea
        ],
      ),
    );
  }
}
