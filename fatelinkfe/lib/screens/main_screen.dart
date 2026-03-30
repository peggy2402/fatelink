import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatelinkfe/screens/home_screen.dart';
import 'package:fatelinkfe/screens/chat_screen.dart';
import 'package:fatelinkfe/screens/profile_screen.dart';
import 'package:fatelinkfe/widgets/custom_bottom_nav_bar.dart';
import 'package:fatelinkfe/widgets/floating_ai_bubble.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showOnboarding = false;
  bool _hasStartedChat = false;
  bool _isLoading = true; // Để hiển thị loading khi check SharedPreferences

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    // Nếu chưa có key 'has_started_chat' hoặc giá trị là false, thì đây là lần đầu
    final hasChatted = prefs.getBool('has_started_chat') ?? false;

    if (mounted) {
      setState(() {
        _hasStartedChat = hasChatted;
        _showOnboarding = !hasChatted;
        _isLoading = false;
      });
    }
  }

  void _handleStartChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_started_chat', true);
    if (mounted) {
      setState(() {
        _showOnboarding = false;
        _hasStartedChat = true;
        _currentIndex = 1; // Chuyển sang tab Chat
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra bàn phím có đang bật không để tự động ẩn thanh điều hướng
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Danh sách các màn hình tương ứng với các tab
    final List<Widget> screens = [
      HomeScreen(
        showOnboarding: _showOnboarding,
        onStartChat: _handleStartChat,
      ),
      const ChatScreen(),
      const Center(
        child: Text(
          "Matches (Coming Soon)",
          style: TextStyle(color: Colors.white),
        ),
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF001520),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFBD114A)),
            )
          else
            IndexedStack(index: _currentIndex, children: screens),

          // Hiển thị bong bóng AI nếu đã bắt đầu chat và không ở tab Chat
          if (_hasStartedChat && _currentIndex != 1 && !isKeyboardOpen)
            FloatingAiBubble(onTap: () => setState(() => _currentIndex = 1)),

          if (!isKeyboardOpen && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNavBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
              ),
            ),
        ],
      ),
    );
  }
}
