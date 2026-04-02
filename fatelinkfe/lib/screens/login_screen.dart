import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fatelinkfe/screens/main_screen.dart';
import 'package:fatelinkfe/utils/toast_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // LƯU Ý QUAN TRỌNG: serverClientId PHẢI LÀ "Web application Client ID" (Loại Web, KHÔNG PHẢI loại Android)
  // Google tự động xác thực Android thông qua mã SHA-1 và Package Name, bạn KHÔNG ĐƯỢC đặt Android Client ID vào đây.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '751936511912-tb3fd241um9i6d3h8u61bmk6tqbbs72p.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // --- CONFIG: Đổi URL của backend tại đây ---
  // Môi trường thật (khi deploy lên Fly.io): 'https://fatelink-be.fly.dev'
  // Môi trường test (máy ảo Android): 'http://10.0.2.2:3000'
  // Môi trường test (máy ảo iOS/Web): 'http://localhost:3000'
  // Môi trường máy Android thật: 'http://192.168.1.8:3000'
  static const String _baseUrl = 'https://fatelink-be.fly.dev';
  // static const String _baseUrl = 'http://10.0.2.2:3000';

  bool _agreedToTerms = true; // Biến lưu trạng thái auto-check điều khoản
  bool _isPressed = false;

  // Khởi tạo Secure Storage
  final _secureStorage = const FlutterSecureStorage();

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupBounceAnimation();
  }

  void _setupBounceAnimation() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  // --- HÀM HỖ TRỢ GHI LOG RA FILE ---
  void _writeLog(String message) {
    debugPrint(message); // Vẫn in ra terminal để backup
    _saveLogToFile(message);
  }

  Future<void> _saveLogToFile(String message) async {
    try {
      // Lấy thư mục lưu trữ (hỗ trợ cả Android và iOS)
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/fatelink_logs.txt');
      final timestamp = DateTime.now().toLocal().toString().split('.')[0];
      await file.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      _writeLog('❌ Lỗi khi ghi file log: $e');
    }
  }

  // --- HÀM HIỂN THỊ LOG LÊN MÀN HÌNH ---
  Future<void> _showLogDialog() async {
    try {
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/fatelink_logs.txt');

      if (await file.exists()) {
        final contents = await file.readAsString();
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('📝 Lịch sử Log'),
              content: SingleChildScrollView(child: Text(contents)),
              actions: [
                TextButton(
                  onPressed: () async {
                    await file.delete();
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Xóa Log',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ToastUtil.showInfo(context, 'Chưa có file log nào được tạo.');
        }
      }
    } catch (e) {
      _writeLog('Lỗi đọc file: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!_agreedToTerms) {
      ToastUtil.showError(
        context,
        'Vui lòng đồng ý với các điều khoản trước khi tiếp tục.',
      );
      return;
    }

    try {
      _writeLog('--- BẮT ĐẦU LUỒNG ĐĂNG NHẬP GOOGLE ---');

      // 1. Mở popup/màn hình đăng nhập Google của hệ điều hành
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _writeLog('⚠️ Người dùng đã đóng popup hoặc hủy đăng nhập.');
        return;
      }
      _writeLog('✅ Lấy được thông tin Google User: ${googleUser.email}');

      // 2. Lấy thông tin xác thực (chứa idToken)
      _writeLog('⏳ Đang lấy Authentication tokens từ Google...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        // Tạm thời in toàn bộ token ra console để copy test trên Postman
        _writeLog('✅ Lấy được FULL ID Token: $idToken');

        // 3. Gửi Token lên Backend NestJS
        // LƯU Ý: Nếu bạn chạy bằng máy ảo Android (Emulator), phải dùng 10.0.2.2 thay vì localhost
        // Nếu chạy trên Web hoặc iOS Simulator, dùng localhost
        final url = '$_baseUrl/auth/google/login';
        _writeLog('🌐 Chuẩn bị gửi POST request tới: $url');

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': idToken}),
        );

        _writeLog('📥 HTTP Status Code nhận được: ${response.statusCode}');
        _writeLog('📥 HTTP Response Body nhận được: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final String backendToken = responseData['accessToken'];

          // 4. Lưu Access Token và Avatar URL vào Secure Storage
          await _secureStorage.write(key: 'accessToken', value: backendToken);

          // Lấy avatar từ backend (nếu API có trả về), nếu không thì lấy trực tiếp từ Google
          final String avatarUrl =
              responseData['user']?['avatar'] ??
              responseData['avatar'] ??
              googleUser.photoUrl ??
              '';
          await _secureStorage.write(key: 'avatarUrl', value: avatarUrl);
          _writeLog('✅ Đã lưu Access Token và Avatar vào Secure Storage!');

          if (mounted) {
            ToastUtil.showSuccess(context, 'Đăng nhập thành công!');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        } else {
          if (mounted)
            ToastUtil.showError(
              context,
              'Không thể kết nối tới máy chủ. Vui lòng thử lại!',
            );
        }
      } else {
        _writeLog('❌ Không lấy được ID Token từ Google');
        if (mounted)
          ToastUtil.showError(
            context,
            'Đăng nhập thất bại: Không lấy được dữ liệu từ Google.',
          );
      }
    } on PlatformException catch (e) {
      String errorMessage = e.message ?? e.toString();
      if (e.code == 'sign_in_failed' ||
          errorMessage.contains('ApiException: 10')) {
        errorMessage =
            'Lỗi cấu hình Google (ApiException: 10).\n\n'
            'Cách sửa:\n'
            '1. Đảm bảo SHA-1 trong Google Cloud Console khớp với keystore đang build.\n'
            '2. Đảm bảo đã tạo Client ID loại "Android" trên Google Cloud.\n'
            '3. Đảm bảo ID dán ở serverClientId là loại "Web application".\n'
            '4. Thêm email test vào màn hình OAuth Consent Screen.';
      }
      _writeLog('❌ LỖI PLATFORM: $errorMessage');
      if (mounted)
        ToastUtil.showError(context, 'Đã xảy ra lỗi hệ thống khi đăng nhập.');
    } catch (error) {
      _writeLog('❌ BẮT ĐƯỢC LỖI TRONG QUÁ TRÌNH ĐĂNG NHẬP: $error');
      if (mounted)
        ToastUtil.showError(
          context,
          'Đăng nhập thất bại. Vui lòng thử lại sau.',
        );
    }
  }

  // --- HÀM MỞ URL ---
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      // Hiển thị lỗi nếu không mở được URL
      _writeLog('❌ Không thể mở URL: $urlString');
      if (mounted) {
        ToastUtil.showError(context, 'Không thể mở liên kết.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001520), // Đồng bộ nền tối
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002B3D), Color(0xFF00080D)], // Gradient xanh đậm
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom:
              false, // Cho phép panel dưới tràn xuống khu vực home indicator
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- Lớp trên cùng: Logo và Support Icon ---
              Positioned(
                top:
                    48, // Bạn có thể điều chỉnh giá trị này để căn dọc đẹp nhất
                left: 24,
                right: 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Khối Logo & Text
                    Image.asset(
                      'assets/icon/app_logo.png',
                      width: 75,
                      height: 75,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FATELINK',
                          style: TextStyle(
                            fontFamily: 'serif',
                            color: Colors.white, // Đổi sang màu trắng
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 12.0,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '🔥Not random! It\'s Fate',
                          style: TextStyle(
                            color: Colors.white70, // Đổi sang màu trắng mờ
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4.0, // Tăng độ dãn chữ
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 8.0, // Glow nhẹ cho slogan
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(), // Đẩy icon support sang phải
                    // Icon Support
                    GestureDetector(
                      onTap: () {
                        _launchURL('$_baseUrl/support.html');
                      },
                      child: Image.asset(
                        'assets/icon/icon-support.png',
                        width: 28,
                        height: 28,
                        colorBlendMode: BlendMode
                            .srcIn, // Áp dụng màu lên hình dạng của ảnh
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.headset_mic_outlined,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Lớp giữa: Ảnh welcome.png ---
              // Dùng Column và Spacer để đẩy ảnh xuống vị trí tương đối
              Column(
                children: [
                  const Spacer(flex: 1), // Giảm flex ở trên để đẩy ảnh lên
                  Image.asset(
                    'assets/images/welcome.png',
                    height: 340,
                    errorBuilder: (c, e, s) => Container(
                      height: 340,
                      width: 240,
                      color: Colors.black12,
                      child: const Icon(Icons.image, color: Colors.black38),
                    ),
                  ),
                  const Spacer(flex: 4), // Tăng flex ở dưới để đẩy ảnh lên
                ],
              ),

              // --- Lớp dưới cùng: Panel đỏ bo góc ---
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height:
                      MediaQuery.of(context).size.height *
                      0.45, // ~45% chiều cao màn hình
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2), // Nền kính mờ
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32.0),
                      topRight: Radius.circular(32.0),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // --- Nút bấm với hiệu ứng ---
                        Listener(
                          onPointerDown: (_) =>
                              setState(() => _isPressed = true),
                          onPointerUp: (_) =>
                              setState(() => _isPressed = false),
                          onPointerCancel: (_) =>
                              setState(() => _isPressed = false),
                          child: AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _bounceAnimation.value),
                                child: Transform.scale(
                                  scale: _isPressed ? 0.95 : 1.0,
                                  child: child,
                                ),
                              );
                            },
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white, // Nút màu trắng nổi bật
                                foregroundColor: Colors.black87,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                                animationDuration: const Duration(
                                  milliseconds: 100,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onPressed: _handleGoogleSignIn,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/icon/icon-google.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.g_mobiledata,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'TIẾP TỤC VỚI GOOGLE',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white54,
                                  thickness: 0.5,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'Các tùy chọn đăng nhập khác',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white54,
                                  thickness: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildImageSocialIcon(
                              'assets/icon/icon-facebook.png',
                            ),
                            const SizedBox(width: 24),
                            _buildImageSocialIcon('assets/icon/icon-zalo.png'),
                            const SizedBox(width: 24),
                            _buildImageSocialIcon(
                              'assets/icon/icon-tiktok.png',
                            ),
                            const SizedBox(width: 24),
                            _buildImageSocialIcon('assets/icon/icon-phone.png'),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreedToTerms = !_agreedToTerms;
                                });

                                if (_agreedToTerms) {
                                  ToastUtil.showSuccess(
                                    context,
                                    'Đã đồng ý với các điều khoản.',
                                  );
                                } else {
                                  ToastUtil.showInfo(
                                    context,
                                    'Vui lòng đồng ý điều khoản để tiếp tục nhé.',
                                  );
                                }
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: Icon(
                                  _agreedToTerms
                                      ? Icons
                                            .check_circle // Fill đặc hình tròn
                                      : Icons.radio_button_unchecked,
                                  key: ValueKey<bool>(_agreedToTerms),
                                  color: _agreedToTerms
                                      ? Colors
                                            .lightBlueAccent // Màu xanh dương sáng
                                      : Colors.white70, // Hơi mờ khi chưa tích
                                  size: 22, // Tăng size lên một chút cho dễ bấm
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Tôi đã đọc và đồng ý với ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                  // Cho phép bấm vào dòng chữ này cũng có tác dụng như bấm vào checkbox
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      setState(() {
                                        _agreedToTerms = !_agreedToTerms;
                                      });
                                      if (_agreedToTerms) {
                                        ToastUtil.showSuccess(
                                          context,
                                          'Đã đồng ý với các điều khoản.',
                                        );
                                      } else {
                                        ToastUtil.showInfo(
                                          context,
                                          'Vui lòng đồng ý điều khoản để tiếp tục nhé.',
                                        );
                                      }
                                    },
                                  children: [
                                    TextSpan(
                                      text: 'Điều khoản Dịch vụ',
                                      style: const TextStyle(
                                        color: Colors.lightBlueAccent,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _launchURL('$_baseUrl/terms.html');
                                        },
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Chính sách Riêng Tư',
                                      style: const TextStyle(
                                        color: Colors.lightBlueAccent,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _launchURL('$_baseUrl/privacy.html');
                                        },
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Chính sách Cookie',
                                      style: const TextStyle(
                                        color: Colors.lightBlueAccent,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _launchURL('$_baseUrl/cookies.html');
                                        },
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Quy tắc của nền tảng',
                                      style: const TextStyle(
                                        color: Colors.lightBlueAccent,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _launchURL('$_baseUrl/rules.html');
                                        },
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Quy định an toàn trẻ em SOP',
                                      style: const TextStyle(
                                        color: Colors.lightBlueAccent,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _launchURL(
                                            '$_baseUrl/child-safety.html',
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildImageSocialIcon(String imagePath) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.broken_image, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
