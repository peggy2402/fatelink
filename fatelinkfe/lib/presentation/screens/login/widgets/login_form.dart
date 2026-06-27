import 'package:flutter/material.dart';

import 'email_login_card.dart';
import 'login_divider.dart';
import 'login_form_header.dart';
import 'login_google_button.dart';
import 'login_social_options.dart';
import 'magic_link_card.dart';
import 'register_prompt.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.bounceAnimation,
    required this.obscurePassword,
    required this.isEmailLoginExpanded,
    required this.isLoading,
    required this.isGoogleLoading,
    required this.isTikTokLoading,
    required this.isZaloLoading,
    required this.isEmailLoading,
    required this.appVersion,
    required this.onGoogleSignIn,
    required this.onTikTokSignIn,
    required this.onZaloSignIn,
    required this.onEmailLogin,
    required this.onToggleEmailLoginExpanded,
    required this.onTogglePasswordVisibility,
    required this.onShowMagicLinkSheet,
    required this.onShowPhoneOtpSheet,
    required this.onShowEmailLoginSheet,
    required this.onShowEmailRegisterSheet,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Animation<double> bounceAnimation;
  final bool obscurePassword;
  final bool isEmailLoginExpanded;
  final bool isLoading;
  final bool isGoogleLoading;
  final bool isTikTokLoading;
  final bool isZaloLoading;
  final bool isEmailLoading;
  final String appVersion;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onTikTokSignIn;
  final VoidCallback onZaloSignIn;
  final VoidCallback onEmailLogin;
  final VoidCallback onToggleEmailLoginExpanded;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onShowMagicLinkSheet;
  final VoidCallback onShowPhoneOtpSheet;
  final VoidCallback onShowEmailLoginSheet;
  final VoidCallback onShowEmailRegisterSheet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 20.0 : 28.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            6,
            horizontalPadding,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LoginSupportButton(),
                  const SizedBox(height: 2),
                  const LoginLogoMark(),
                  const SizedBox(height: 12),
                  const LoginBrandTitle(),
                  const SizedBox(height: 12),
                  const Text(
                    'Đăng nhập để tiếp tục kết nối',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF697287), fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  LoginGoogleButton(
                    isLoading: isGoogleLoading,
                    bounceAnimation: bounceAnimation,
                    onPressed: onGoogleSignIn,
                  ),
                  const SizedBox(height: 18),
                  const LoginDivider('hoặc đăng nhập bằng'),
                  const SizedBox(height: 18),
                  LoginSocialOptionsRow(
                    isLoading: isLoading,
                    isTikTokLoading: isTikTokLoading,
                    isZaloLoading: isZaloLoading,
                    onTikTokSignIn: onTikTokSignIn,
                    onZaloSignIn: onZaloSignIn,
                    onShowPhoneOtpSheet: onShowPhoneOtpSheet,
                  ),
                  const SizedBox(height: 18),
                  const LoginDivider('hoặc'),
                  const SizedBox(height: 18),
                  EmailLoginCard(
                    emailController: emailController,
                    passwordController: passwordController,
                    obscurePassword: obscurePassword,
                    isExpanded: isEmailLoginExpanded,
                    isLoading: isEmailLoading,
                    onPressed: onEmailLogin,
                    onToggleExpanded: onToggleEmailLoginExpanded,
                    onTogglePasswordVisibility: onTogglePasswordVisibility,
                    onForgotPassword: onShowMagicLinkSheet,
                  ),
                  const SizedBox(height: 18),
                  MagicLinkCard(onTap: onShowMagicLinkSheet),
                  const SizedBox(height: 8),
                  RegisterPrompt(onPressed: onShowEmailRegisterSheet),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
