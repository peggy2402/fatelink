import 'package:flutter/material.dart';
import 'package:fatelinkfe/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatelinkfe/presentation/screens/login_screen.dart';

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
      'color': AppColors.primary, // Màu Rose/Pink đặc trưng của FateLink
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: data['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data['icon'], size: 100, color: data['color']),
                ),
              );
            },
          ),
          const SizedBox(height: 60),
          Text(
            data['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1F1F),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data['description'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Custom Dots Indicator
          Row(
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

          // Nút Tiếp Tục / Đồng Ý
          ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
              shadowColor: AppColors.primary.withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentPage == _onboardingData.length - 1
                      ? 'Tôi Đồng Ý'
                      : 'Tiếp tục',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_currentPage != _onboardingData.length - 1) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
