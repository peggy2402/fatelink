import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/presentation/screens/home/home_screen.dart';
import 'package:fatelinkfe/presentation/screens/chat/chat_screen.dart';
import 'package:fatelinkfe/presentation/screens/explore/explore_screen.dart';
import 'package:fatelinkfe/presentation/screens/profile/profile_screen.dart';
import 'package:fatelinkfe/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:fatelinkfe/presentation/widgets/floating_ai_bubble.dart';
import 'package:fatelinkfe/presentation/widgets/chat_input_bar.dart';
import 'package:fatelinkfe/presentation/widgets/menu.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../logic/blocs/main/main_bloc.dart';
import '../../logic/blocs/main/main_event.dart';
import '../../logic/blocs/main/main_state.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../../logic/blocs/auth/auth_state.dart';
import '../../logic/blocs/chat/chat_bloc.dart';
import '../../logic/blocs/chat/chat_event.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  bool _showOnboarding = false;
  bool _hasStartedChat = false;
  bool _isLoading = true; // Để hiển thị loading khi check SharedPreferences
  bool _hasUnreadMessages = false; // Biến lưu trạng thái có tin nhắn mới
  String? _avatarUrl; // Biến lưu URL ảnh đại diện
  ChatView _chatView = ChatView.list; // State để biết đang ở list hay room

  final TextEditingController _chatController = TextEditingController();
  bool _isPopupOpen = false;
  bool _isMenuOpen = false;
  AnimationController? _menuController;
  Animation<Offset>? _menuSlide;
  Animation<double>? _menuFade;

  @override
  void initState() {
    super.initState();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _menuController = controller;
    _menuSlide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _menuFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));
    _checkFirstTime();
  }

  void _openMenu() {
    setState(() => _isMenuOpen = true);
    _menuController?.forward();
  }

  void _closeMenu() {
    _menuController?.reverse().then((_) {
      if (mounted) setState(() => _isMenuOpen = false);
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    // Nếu chưa có key 'has_started_chat' hoặc giá trị là false, thì đây là lần đầu
    final hasChatted = prefs.getBool('has_started_chat') ?? false;

    // Lấy URL ảnh đại diện đã lưu từ FlutterSecureStorage
    const secureStorage = FlutterSecureStorage();
    final avatar = await secureStorage.read(
      key: 'avatarUrl',
    ); // Key này phải khớp với key bạn lưu lúc Login

    if (mounted) {
      setState(() {
        _avatarUrl = avatar;
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
        _hasUnreadMessages = false;
      });
      context.read<MainBloc>().add(const ChangeTabEvent(2)); // Chuyển sang tab Chat qua BLoC (Index 2)
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _menuController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra bàn phím có đang bật không để tự động ẩn thanh điều hướng
    final currentIndex = context.watch<MainBloc>().state.selectedIndex;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Bị đăng xuất (logout) hoặc token hết hạn -> văng ra màn hình Login
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF001520),
        body: BlocBuilder<MainBloc, MainState>(
        builder: (context, mainState) {

          // Đưa danh sách screens vào trong builder để truy cập được currentIndex
          final List<Widget> screens = [
            HomeScreen(
              showOnboarding: _showOnboarding,
              onStartChat: _handleStartChat,
            ),
            const ExploreScreen(),
            ChatScreen(
              onBack: () {
                context.read<MainBloc>().add(const ChangeTabEvent(0));
                setState(() => _isPopupOpen = false); // Đóng popup nếu đang mở
              },
              onNewMessage: () {
                if (currentIndex != 2) {
                  // Chỉ hiện chấm đỏ nếu đang KHÔNG ở tab Chat
                  setState(() => _hasUnreadMessages = true);
                }
              },
              onViewChanged: (view) {
                if (_chatView != view) {
                  setState(() => _chatView = view);
                }
              },
            ),
            ProfileScreen(onMenuTap: _openMenu),
          ];

          return Stack(
            children: [
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBD114A)),
                )
              else
                IndexedStack(index: mainState.selectedIndex, children: screens),

              // Lớp Blur mờ phía sau khi mở Modal Popup
              if (_isPopupOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPopupOpen = false),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),
                  ),
                ),

              // Custom Modal Popup (Nổi lên từ nút +)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut, // Hiệu ứng Bounce (Spring Physics)
                bottom: _isPopupOpen ? 110.0 : 40.0, // Vị trí nảy lên
                left: 24,
                child: AnimatedScale(
                  scale: _isPopupOpen ? 1.0 : 0.5, // Hiệu ứng Scale lớn dần
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isPopupOpen ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !_isPopupOpen,
                      child: _buildCustomPopup(),
                    ),
                  ),
                ),
              ),

              // Thanh Điều Hướng hoặc Thanh Chat Input
              if (!_isLoading &&
                  (!isKeyboardOpen || (mainState.selectedIndex == 2 && _chatView == ChatView.room)))
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.8), // Trượt từ dưới lên
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: (mainState.selectedIndex == 2 && _chatView == ChatView.room)
                        ? ChatInputBar(
                            key: const ValueKey('chatBar'),
                            controller: _chatController,
                            onSubmitted: (text) {
                              if (text.trim().isNotEmpty) {
                                context.read<ChatBloc>().add(ChatSendMessageEvent(text.trim()));
                                _chatController.clear();
                              }
                            },
                          )
                        : CustomBottomNavBar(
                            key: const ValueKey('navBar'),
                            currentIndex: currentIndex,
                            avatarUrl: _avatarUrl,
                            onTap: (index) {
                              context.read<MainBloc>().add(ChangeTabEvent(index));
                              setState(() {
                                _isPopupOpen = false;
                                if (index == 2) _hasUnreadMessages = false;
                              });
                            },
                          ),
                  ),
                ),

              // Hiển thị bong bóng AI nếu đã bắt đầu chat và không ở tab Chat (Đưa xuống cuối để nổi lên trên cùng)
              if (_hasStartedChat &&
                  mainState.selectedIndex != 2 &&
                  !isKeyboardOpen &&
                  !_isPopupOpen)
                FloatingAiBubble(
                  hasNotification: _hasUnreadMessages,
                  onTap: () {
                    context.read<MainBloc>().add(const ChangeTabEvent(2));
                    setState(() {
                      _hasUnreadMessages = false; // Tắt chấm đỏ khi đã vào Chat
                    });
                  },
                ),

              // Menu overlay (đặt cuối cùng, có animation đóng/mở)
              if (_isMenuOpen || (_menuController?.value ?? 0) > 0)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeMenu,
                    child: AnimatedBuilder(
                      animation: _menuController!,
                      builder: (context, _) {
                        return Stack(
                          children: [
                            Container(
                              color: Colors.black.withOpacity(
                                0.3 * (_menuFade?.value ?? 0),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FractionalTranslation(
                                translation: _menuSlide?.value ?? Offset.zero,
                                child: AppMenuDrawer(onClose: _closeMenu),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      ),
    );
  }

  // --- UI Custom Modal Popup ---
  Widget _buildCustomPopup() {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF001520), // Xanh navy đậm
        borderRadius: BorderRadius.circular(32), // Bo góc cực đại
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPopupItem(Icons.home_filled, 'Home'.tr(), 0, Colors.blueAccent),
          _buildPopupItem(
            Icons.favorite_border,
            'Matches'.tr(),
            2,
            Colors.pinkAccent,
          ),
          _buildPopupItem(
            Icons.person_outline,
            'Profile'.tr(),
            3,
            Colors.deepPurpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPopupItem(
    IconData icon,
    String label,
    int index,
    Color iconColor,
  ) {
    return _AnimatedPopupItem(
      icon: icon,
      label: label,
      iconColor: iconColor,
      onTap: () {
        context.read<MainBloc>().add(ChangeTabEvent(index));
        setState(() {
          _isPopupOpen = false;
        });
      },
    );
  }
}

class _AnimatedPopupItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _AnimatedPopupItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_AnimatedPopupItem> createState() => _AnimatedPopupItemState();
}

class _AnimatedPopupItemState extends State<_AnimatedPopupItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.8 : 1.0, // Hiệu ứng thu nhỏ khi nhấn giữ
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
