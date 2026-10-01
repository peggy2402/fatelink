import 'package:flutter/material.dart';

import 'auth_tab_switcher.dart';
import 'email_login_card.dart';
import 'login_divider.dart';
import 'login_form_header.dart';
import 'login_google_button.dart';
import 'login_social_options.dart';
import 'magic_link_card.dart';
import 'register_form_card.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.isLoginMode,
    required this.onTabChanged,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.bounceAnimation,
    required this.obscurePassword,
    required this.isEmailLoginExpanded,
    required this.isLoading,
    required this.isGoogleLoading,
    required this.isTikTokLoading,
    required this.isZaloLoading,
    required this.isEmailLoading,
    required this.isRegisterLoading,
    required this.appVersion,
    required this.onGoogleSignIn,
    required this.onTikTokSignIn,
    required this.onZaloSignIn,
    required this.onEmailLogin,
    required this.onEmailRegister,
    required this.onToggleEmailLoginExpanded,
    required this.onTogglePasswordVisibility,
    required this.onShowMagicLinkSheet,
    required this.onShowPhoneOtpSheet,
  });

  final bool isLoginMode;
  final ValueChanged<bool> onTabChanged;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Animation<double> bounceAnimation;
  final bool obscurePassword;
  final bool isEmailLoginExpanded;
  final bool isLoading;
  final bool isGoogleLoading;
  final bool isTikTokLoading;
  final bool isZaloLoading;
  final bool isEmailLoading;
  final bool isRegisterLoading;
  final String appVersion;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onTikTokSignIn;
  final VoidCallback onZaloSignIn;
  final VoidCallback onEmailLogin;
  final VoidCallback onEmailRegister;
  final VoidCallback onToggleEmailLoginExpanded;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onShowMagicLinkSheet;
  final VoidCallback onShowPhoneOtpSheet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360 ? 18.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Bar: Support Icon Button
                  const LoginSupportButton(),
                  const SizedBox(height: 6),

                  // 2. Branding Header: 3D Pulse Heart + PRO Badge + Title + Slogan
                  const LoginLogoMark(),
                  const SizedBox(height: 14),
                  const LoginBrandTitle(),
                  const SizedBox(height: 8),
                  const LoginSlogan(),
                  const SizedBox(height: 22),

                  // 3. Tab Switcher: [Đăng nhập] vs [Tạo tài khoản mới]
                  AuthTabSwitcher(
                    isLogin: isLoginMode,
                    onTabChanged: onTabChanged,
                  ),
                  const SizedBox(height: 22),

                  // 4. Form Content based on Active Tab
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: isLoginMode
                        ? _buildLoginContent()
                        : _buildRegisterContent(),
                  ),

                  const SizedBox(height: 24),

                  // App Version note
                  if (appVersion.isNotEmpty)
                    Text(
                      appVersion,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
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

  Widget _buildLoginContent() {
    return Column(
      key: const ValueKey('login_content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary CTA: Tiếp tục với Google
        LoginGoogleButton(
          isLoading: isGoogleLoading,
          bounceAnimation: bounceAnimation,
          onPressed: onGoogleSignIn,
        ),
        const SizedBox(height: 18),

        // Divider
        const LoginDivider('hoặc đăng nhập nhanh qua'),
        const SizedBox(height: 18),

        // Social options row (Facebook, TikTok, Zalo, Phone SMS OTP)
        LoginSocialOptionsRow(
          isLoading: isLoading,
          isTikTokLoading: isTikTokLoading,
          isZaloLoading: isZaloLoading,
          onTikTokSignIn: onTikTokSignIn,
          onZaloSignIn: onZaloSignIn,
          onShowPhoneOtpSheet: onShowPhoneOtpSheet,
        ),
        const SizedBox(height: 18),

        // Divider
        const LoginDivider('hoặc sử dụng email'),
        const SizedBox(height: 18),

        // Accordion Email Login Card
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
        const SizedBox(height: 16),

        // Magic Link Passwordless Card
        MagicLinkCard(onTap: onShowMagicLinkSheet),
      ],
    );
  }

  Widget _buildRegisterContent() {
    return Column(
      key: const ValueKey('register_content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Register Form Card
        RegisterFormCard(
          nameController: nameController,
          emailController: emailController,
          passwordController: passwordController,
          confirmPasswordController: confirmPasswordController,
          obscurePassword: obscurePassword,
          isLoading: isRegisterLoading,
          onTogglePasswordVisibility: onTogglePasswordVisibility,
          onRegister: onEmailRegister,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
