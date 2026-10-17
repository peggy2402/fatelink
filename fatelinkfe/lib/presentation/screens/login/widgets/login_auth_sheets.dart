import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../logic/blocs/auth/auth_bloc.dart';
import '../../../../logic/blocs/auth/auth_event.dart';
import '../../../../core/utils/toast_utils.dart';

void _showSheetMessage(BuildContext context, String message) {
  ToastUtil.showWarning(context, message);
}

bool _isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}

InputDecoration _sheetInputDecoration({
  required String labelText,
  required IconData icon,
  String? hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    hintStyle: const TextStyle(
      fontFamily: 'BeVietnamPro',
      color: Color(0xFF94A3B8),
      fontSize: 13,
    ),
    prefixIcon: Icon(icon, color: const Color(0xFFEF3D8B)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFFFFBFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFF0E5EC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFF0E5EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFEF3D8B), width: 1.4),
    ),
  );
}

Future<void> showEmailAuthSheet(
  BuildContext context, {
  required bool isRegister,
}) async {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final dobController = TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFCFD),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final mediaQuery = MediaQuery.of(sheetContext);
          final bottomPadding = mediaQuery.viewInsets.bottom + math.max(mediaQuery.padding.bottom, 24.0);

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 18,
                bottom: bottomPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8DDE8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isRegister ? 'Đăng ký bằng email' : 'Đăng nhập bằng email',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF35164F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRegister
                        ? 'Tạo tài khoản bằng email, tên hiển thị & ngày sinh.'
                        : 'Nhập email và mật khẩu để tiếp tục.',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF7B8192),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isRegister) ...[
                    TextField(
                      controller: nameController,
                      decoration: _sheetInputDecoration(
                        labelText: 'Tên hiển thị',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(now.year - 20, 1, 1),
                          firstDate: DateTime(1940),
                          lastDate: DateTime(now.year - 16, now.month, now.day),
                          helpText: 'CHỌN NGÀY SINH CỦA BẠN',
                        );
                        if (picked != null) {
                          setSheetState(() {
                            dobController.text =
                                '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: dobController,
                          decoration: _sheetInputDecoration(
                            labelText: 'Ngày sinh',
                            icon: Icons.cake_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _sheetInputDecoration(
                      labelText: 'Email',
                      icon: Icons.mail_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _sheetInputDecoration(
                      labelText: 'Mật khẩu',
                      icon: Icons.lock_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF3D8B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text;
                        final name = nameController.text.trim();

                        if (isRegister && name.isEmpty) {
                          _showSheetMessage(
                            sheetContext,
                            'Vui lòng nhập tên hiển thị.',
                          );
                          return;
                        }

                        if (isRegister && dobController.text.isEmpty) {
                          _showSheetMessage(
                            sheetContext,
                            'Vui lòng chọn ngày sinh của bạn.',
                          );
                          return;
                        }

                        if (!_isValidEmail(email)) {
                          _showSheetMessage(
                            sheetContext,
                            'Vui lòng nhập email hợp lệ.',
                          );
                          return;
                        }

                        if (password.length < 6) {
                          _showSheetMessage(
                            sheetContext,
                            'Mật khẩu phải có ít nhất 6 ký tự.',
                          );
                          return;
                        }

                        final navigator = Navigator.of(sheetContext);
                        final authBloc = context.read<AuthBloc>();
                        if (isRegister && dobController.text.isNotEmpty) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('user_dob', dobController.text);
                          await prefs.setString('userName', name);
                        }

                        navigator.pop();
                        if (isRegister) {
                          authBloc.add(
                            AuthEmailRegisterRequested(
                              email: email,
                              password: password,
                              name: name,
                            ),
                          );
                        } else {
                          authBloc.add(
                            AuthEmailLoginRequested(
                              email: email,
                              password: password,
                            ),
                          );
                        }
                      },
                      child: Text(
                        isRegister ? 'Đăng ký ngay' : 'Đăng nhập',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Modal thông báo trạng thái cổng SMS OTP (tạm hoãn kinh phí viễn thông)
Future<void> showPhoneOtpSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFCFD),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DDE8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phonelink_setup_rounded,
                  color: Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cổng SMS OTP Đang Nâng Cấp',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tính năng gửi OTP qua tin nhắn SMS viễn thông đang được kết nối với nhà mạng để đảm bảo chi phí tối ưu nhất cho cộng đồng.\n\nBạn vui lòng đăng nhập tiện lợi & bảo mật qua Google, Email hoặc nhận Magic Link miễn phí nhé! ✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13.5,
                  height: 1.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        showMagicLinkSheet(context);
                      },
                      child: const Text(
                        'Dùng Magic Link',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Modal đăng nhập bằng Magic Link (Không cần mật khẩu)
Future<void> showMagicLinkSheet(BuildContext context) async {
  final emailController = TextEditingController();
  final tokenController = TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFCFD),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final mediaQuery = MediaQuery.of(sheetContext);
          final bottomPadding = mediaQuery.viewInsets.bottom + math.max(mediaQuery.padding.bottom, 24.0);

          return DefaultTabController(
            length: 2,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 18,
                  bottom: bottomPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8DDE8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFEF3D8B),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Đăng nhập Magic Link',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF35164F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đăng nhập 1 chạm an toàn qua email mà không cần ghi nhớ mật khẩu.',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        color: Color(0xFF7B8192),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab selector: [1. Gửi link] vs [2. Dán mã / Link]
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        labelColor: const Color(0xFFEF3D8B),
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: '1. Gửi liên kết'),
                          Tab(text: '2. Dán link xác thực'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      height: 190,
                      child: TabBarView(
                        children: [
                          // Tab 1: Yêu cầu gửi magic link
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _sheetInputDecoration(
                                  labelText: 'Email của bạn',
                                  hintText: 'VD: ban@gmail.com',
                                  icon: Icons.mark_email_read_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF3D8B),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 18),
                                label: const Text(
                                  'Gửi liên kết đăng nhập',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                onPressed: () {
                                  final email = emailController.text.trim();
                                  if (!_isValidEmail(email)) {
                                    _showSheetMessage(
                                      sheetContext,
                                      'Vui lòng nhập email hợp lệ.',
                                    );
                                    return;
                                  }
                                  context.read<AuthBloc>().add(
                                    AuthMagicLinkRequestRequested(email: email),
                                  );
                                  ToastUtil.showInfo(
                                    context,
                                    'Đang yêu cầu Magic Link cho $email... Hãy kiểm tra hộp thư nhé!',
                                  );
                                },
                              ),
                            ],
                          ),

                          // Tab 2: Xác thực token / URL Magic Link
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: tokenController,
                                decoration: _sheetInputDecoration(
                                  labelText: 'Token hoặc Link xác thực',
                                  hintText: 'Dán link hoặc token nhận từ email...',
                                  icon: Icons.vpn_key_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(Icons.lock_open_rounded, size: 18),
                                label: const Text(
                                  'Xác thực & Vào App ngay',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                onPressed: () {
                                  var input = tokenController.text.trim();
                                  if (input.isEmpty) {
                                    _showSheetMessage(
                                      sheetContext,
                                      'Vui lòng dán mã token hoặc liên kết Magic Link.',
                                    );
                                    return;
                                  }

                                  // Tự động bóc tách token nếu người dùng dán toàn bộ URL
                                  if (input.contains('token=')) {
                                    try {
                                      final uri = Uri.parse(input);
                                      final parsedToken = uri.queryParameters['token'];
                                      if (parsedToken != null && parsedToken.isNotEmpty) {
                                        input = parsedToken;
                                      }
                                    } catch (_) {}
                                  }

                                  Navigator.pop(sheetContext);
                                  context.read<AuthBloc>().add(
                                    AuthMagicLinkLoginRequested(token: input),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Modal đăng nhập bằng Facebook Access Token
Future<void> showFacebookAuthSheet(BuildContext context) async {
  final tokenController = TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFCFD),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      final mediaQuery = MediaQuery.of(sheetContext);
      final bottomPadding = mediaQuery.viewInsets.bottom + math.max(mediaQuery.padding.bottom, 24.0);

      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 18,
            bottom: bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DDE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(
                    Icons.facebook_rounded,
                    color: Color(0xFF1877F2),
                    size: 26,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đăng nhập Facebook',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhập hoặc dán Facebook User Access Token để xác thực tài khoản qua API Meta Graph an toàn.',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                maxLines: 2,
                decoration: _sheetInputDecoration(
                  labelText: 'Facebook Access Token',
                  hintText: 'Dán token từ Facebook Login hoặc Graph Explorer...',
                  icon: Icons.key_rounded,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text(
                    'Xác thực & Đăng nhập Facebook',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    final token = tokenController.text.trim();
                    if (token.isEmpty) {
                      _showSheetMessage(
                        sheetContext,
                        'Vui lòng nhập Facebook Access Token.',
                      );
                      return;
                    }

                    Navigator.pop(sheetContext);
                    context.read<AuthBloc>().add(
                      AuthLoginRequested(
                        provider: AuthSocialProvider.facebook,
                        accessToken: token,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
