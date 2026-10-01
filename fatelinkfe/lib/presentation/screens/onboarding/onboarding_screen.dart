import 'package:flutter/material.dart';
import 'package:fatelinkfe/core/constants/app_colors.dart';
import 'package:fatelinkfe/core/responsive/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'icon': Icons.smart_toy_rounded,
      'color': Colors.indigo,
      'title': 'Giai đoạn 1:\nAI Thấu Hiểu',
      'description':
          'Trợ lý AI sẽ trò chuyện cùng bạn để phân tích tính cách, sở thích và định hình chính xác "gu" người yêu lý tưởng của bạn.',
    },
    {
      'icon': Icons.radar_rounded,
      'color': Colors.pinkAccent,
      'title': 'Giai đoạn 2:\nSmart Matching',
      'description':
          'Quét và tìm ra những mảnh ghép có độ tương thích cao nhất, được chọn lọc dành riêng cho bạn.',
    },
    {
      'icon': Icons.rocket_launch_rounded,
      'color': AppColors.primary, // Màu Rose/Pink đặc trưng của Meyu
      'title': 'Bước tiếp theo:\nKhởi hành',
      'description':
          'Hãy chuẩn bị một tâm hồn đẹp và một profile ấn tượng. Những kết nối và cuộc trò chuyện thú vị đang chờ đón bạn phía trước!',
    },
  ];

  void _onNext() {
    if (_currentPage == _onboardingData.length - 1) {
      // Đã ở slide cuối, chuyển sang Login
      _navigateToLogin();
    } else {
      // Chuyển sang slide tiếp theo
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    }
  }

  Future<void> _navigateToLogin() async {
    // Lưu cờ (flag) vào SharedPreferences để không hiện lại Onboarding lần sau
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);

    if (!mounted) return;

    // Sử dụng pushReplacement để không cho phép back lại Onboarding
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              'Bỏ qua',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_onboardingData[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 520;
        final iconSize = isShort ? 68.0 : 96.0;
        final iconPadding = isShort ? 22.0 : 30.0;
        final spacing1 = isShort ? 24.0 : 48.0;
        final spacing2 = isShort ? 12.0 : 18.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
          child: ResponsiveCenter(
            maxWidth: 540,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hiệu ứng icon bay bổng
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: EdgeInsets.all(iconPadding),
                          decoration: BoxDecoration(
                            color: (data['color'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(data['icon'] as IconData, size: iconSize, color: data['color'] as Color),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: spacing1),
                  Text(
                    data['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isShort ? 22 : 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F1F1F),
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: spacing2),
                  Text(
                    data['description'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isShort ? 14 : 15.5,
                      color: Colors.grey.shade600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return ResponsiveCenter(
      maxWidth: 540,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Custom Dots Indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nút Tiếp Tục / Đồng Ý
            Flexible(
              child: ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _currentPage == _onboardingData.length - 1
                            ? 'Tôi Đồng Ý'
                            : 'Tiếp tục',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_currentPage != _onboardingData.length - 1) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
