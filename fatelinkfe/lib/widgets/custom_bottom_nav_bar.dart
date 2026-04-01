import 'package:flutter/material.dart';

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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Khởi tạo AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Hiệu ứng trượt từ dưới lên (Offset y từ 1.0 về 0.0)
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuint,
          ),
        );

    // Hiệu ứng mờ dần sang rõ
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Bắt đầu chạy animation khi Widget được render lần đầu
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Container(
            height: 72,
            margin: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 24,
            ), // Thanh bar nổi (Floating)
            decoration: BoxDecoration(
              color: const Color(0xFF001520), // Xanh navy đậm
              borderRadius: BorderRadius.circular(
                100,
              ), // Bo góc tròn cực đại (Capsule)
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Tính toán chiều rộng của mỗi item để di chuyển Highlight Pill
                final itemWidth = constraints.maxWidth / 4;

                return Stack(
                  children: [
                    // Vòng tròn highlight xanh sáng di chuyển
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: widget.currentIndex * itemWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: itemWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1E88E5,
                            ).withOpacity(0.25), // Xanh sáng nhẹ
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    // Các nút điều hướng
                    SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Row(
                        children: [
                          _buildNavItem(
                            0,
                            'Home',
                            'assets/icon/home.png',
                            activeAssetPath: 'assets/icon/home_active.png',
                          ),
                          _buildNavItem(
                            1,
                            'Chat',
                            'assets/icon/chat.png',
                            activeAssetPath: 'assets/icon/chat_active.png',
                            hasBadge: true,
                          ),
                          _buildNavItem(
                            2,
                            'Matches',
                            'assets/icon/matches.png',
                            activeAssetPath: 'assets/icon/matches_active.png',
                          ),
                          _buildNavItem(
                            3,
                            'Profile',
                            '',
                          ), // Index 3 sẽ dùng CircleAvatar
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    String assetPath, {
    String? activeAssetPath,
    bool hasBadge = false,
  }) {
    final isSelected = widget.currentIndex == index;

    // Khôi phục lại logic đổi sang màu VÀNG NHẠT khi chọn
    final color = isSelected ? const Color(0xFFFFF9C4) : Colors.white54;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AnimatedContainer tạo hiệu ứng scale nhẹ khi chọn
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
              transformAlignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (index == 3)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFF9C4)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      // ClipOval kết hợp errorBuilder giúp chống crash tuyệt đối
                      child: ClipOval(
                        child:
                            widget.avatarUrl != null &&
                                widget.avatarUrl!.isNotEmpty
                            ? Image.network(
                                widget.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackAvatar(color),
                              )
                            : _buildFallbackAvatar(color),
                      ),
                    )
                  else
                    Image.asset(
                      (isSelected &&
                              activeAssetPath != null &&
                              activeAssetPath.isNotEmpty)
                          ? activeAssetPath
                          : assetPath,
                      width: 26,
                      height: 26,
                      color: isSelected
                          ? null
                          : color, // Không ám màu nếu đang chọn (để giữ nguyên viền trắng, lõi vàng của ảnh active)
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(_getFallbackIcon(index), color: color, size: 26),
                    ),

                  // Badge thông báo cho tab Chat
                  if (hasBadge)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(
                          4,
                        ), // Tạo độ phồng cho hình tròn quanh số
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF001520),
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          '1', // Hiển thị số 1 (Bạn có thể biến thành tham số động sau này)
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
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
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm phụ trợ tạo Avatar dự phòng cực kỳ an toàn
  Widget _buildFallbackAvatar(Color color) {
    return Image.asset(
      'assets/images/default_avatar.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.withOpacity(0.5),
        child: Icon(
          Icons.person,
          color: color,
          size: 20,
        ), // Trả về Icon rỗng nếu mất file ảnh
      ),
    );
  }

  // Hàm phụ trợ giúp hiển thị Icon mặc định trong trường hợp bạn chưa kịp thêm ảnh vào thư mục assets
  IconData _getFallbackIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_filled;
      case 1:
        return Icons.chat_bubble_outline;
      case 2:
        return Icons.favorite_border;
      default:
        return Icons.person;
    }
  }
}
