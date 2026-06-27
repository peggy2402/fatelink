import 'package:flutter/material.dart';

import 'email_login_button.dart';
import 'login_input_field.dart';

class EmailLoginCard extends StatelessWidget {
  const EmailLoginCard({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isExpanded,
    required this.isLoading,
    required this.onPressed,
    required this.onToggleExpanded,
    required this.onTogglePasswordVisibility,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isExpanded;
  final bool isLoading;
  final VoidCallback onPressed;
  final VoidCallback onToggleExpanded;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E5EC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB4D1).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    color: Color(0xFFEF3D8B),
                    size: 34,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Đăng nhập bằng email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFFEF3D8B),
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LoginInputField(
                    controller: emailController,
                    hintText: 'Email của bạn',
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  LoginInputField(
                    controller: passwordController,
                    hintText: 'Mật khẩu của bạn',
                    icon: Icons.lock_outline_rounded,
                    obscureText: obscurePassword,
                    suffix: IconButton(
                      onPressed: onTogglePasswordVisibility,
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF7D879C),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF3D8B),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  EmailLoginButton(isLoading: isLoading, onPressed: onPressed),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}
