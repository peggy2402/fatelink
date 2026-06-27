import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../logic/blocs/auth/auth_bloc.dart';
import '../../../../logic/blocs/auth/auth_event.dart';

void _showSheetMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

bool _isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}

bool _isValidPhone(String value) {
  final phone = value.trim();
  return RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone);
}

InputDecoration _sheetInputDecoration({
  required String labelText,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: labelText,
    prefixIcon: Icon(icon, color: const Color(0xFFEF3D8B)),
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

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFCFD),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 18,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
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
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF35164F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isRegister
                  ? 'Tạo tài khoản bằng email và mật khẩu của bạn.'
                  : 'Nhập email và mật khẩu để tiếp tục.',
              style: const TextStyle(
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
                onPressed: () {
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

                  Navigator.pop(sheetContext);
                  if (isRegister) {
                    context.read<AuthBloc>().add(
                      AuthEmailRegisterRequested(
                        email: email,
                        password: password,
                        name: name,
                      ),
                    );
                  } else {
                    context.read<AuthBloc>().add(
                      AuthEmailLoginRequested(
                        email: email,
                        password: password,
                      ),
                    );
                  }
                },
                child: Text(isRegister ? 'Đăng ký' : 'Đăng nhập'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showPhoneOtpSheet(BuildContext context) async {
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final otpController = TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFCFD),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 18,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
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
            const Text(
              'Đăng nhập bằng số điện thoại',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF35164F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhận mã OTP rồi nhập lại để đăng nhập nhanh trên thiết bị này.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF7B8192),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: _sheetInputDecoration(
                labelText: 'Số điện thoại',
                icon: Icons.phone_iphone_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: _sheetInputDecoration(
                labelText: 'Tên hiển thị (lần đầu)',
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: _sheetInputDecoration(
                labelText: 'Mã OTP',
                icon: Icons.password_rounded,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF3D8B),
                      side: const BorderSide(color: Color(0xFFF3A9C9)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      final phoneNumber = phoneController.text.trim();
                      if (!_isValidPhone(phoneNumber)) {
                        _showSheetMessage(
                          sheetContext,
                          'Vui lòng nhập số điện thoại hợp lệ.',
                        );
                        return;
                      }
                      context.read<AuthBloc>().add(
                        AuthPhoneRequestOtpRequested(
                          phoneNumber: phoneNumber,
                          name: nameController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Gửi OTP'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                    onPressed: () {
                      final phoneNumber = phoneController.text.trim();
                      final otpCode = otpController.text.trim();
                      if (!_isValidPhone(phoneNumber)) {
                        _showSheetMessage(
                          sheetContext,
                          'Vui lòng nhập số điện thoại hợp lệ.',
                        );
                        return;
                      }
                      if (otpCode.isEmpty) {
                        _showSheetMessage(
                          sheetContext,
                          'Vui lòng nhập mã OTP.',
                        );
                        return;
                      }
                      Navigator.pop(sheetContext);
                      context.read<AuthBloc>().add(
                        AuthPhoneLoginRequested(
                          phoneNumber: phoneNumber,
                          otpCode: otpCode,
                        ),
                      );
                    },
                    child: const Text('Đăng nhập'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showMagicLinkSheet(BuildContext context) async {
  final emailController = TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFCFD),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 18,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
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
            const Text(
              'Gửi magic link',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF35164F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chỉ cần nhập email. Chúng tôi sẽ gửi một liên kết đăng nhập 1 lần vào hộp thư của bạn.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF7B8192),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _sheetInputDecoration(
                labelText: 'Email',
                icon: Icons.mark_email_read_outlined,
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
                onPressed: () {
                  final email = emailController.text.trim();
                  if (!_isValidEmail(email)) {
                    _showSheetMessage(
                      sheetContext,
                      'Vui lòng nhập email hợp lệ.',
                    );
                    return;
                  }
                  Navigator.pop(sheetContext);
                  context.read<AuthBloc>().add(
                    AuthMagicLinkRequestRequested(
                      email: email,
                    ),
                  );
                },
                child: const Text('Gửi magic link'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
