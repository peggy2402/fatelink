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
    this.scrollController,
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

  final ScrollController? scrollController;
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
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        final isSmallWidth = availableWidth < 360;
        final horizontalPadding = isSmallWidth ? 16.0 : 22.0;

        // 1. Kích thước logo co theo chiều cao khả dụng, clamp 64–104dp
        final logoSize = (availableHeight * 0.098).clamp(64.0, 104.0);
        final titleSize = (availableHeight * 0.044).clamp(32.0, 42.0);
        final sloganSize = availableHeight < 720 ? 12.0 : 13.5;

        // 2. Khoảng cách dọc co giãn tỷ lệ theo chiều cao (topSpacing chừa chỗ cho nút Hỗ trợ ghim cố định)
        final topSpacing = (availableHeight * 0.08).clamp(52.0, 72.0);
        final logoToTitleGap = (availableHeight * 0.010).clamp(4.0, 10.0);
        final titleToSloganGap = (availableHeight * 0.005).clamp(2.0, 6.0);
        final headerToSwitcherGap = (availableHeight * 0.016).clamp(8.0, 18.0);
        final switcherToFormGap = (availableHeight * 0.016).clamp(8.0, 18.0);
        final formBlockGap = (availableHeight * 0.013).clamp(6.0, 14.0);
        final bottomPadding = (availableHeight * 0.016).clamp(8.0, 20.0);

        return SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topSpacing,
            horizontalPadding,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                minHeight: (availableHeight - topSpacing - bottomPadding).clamp(0.0, double.infinity),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Branding Header: 3D Pulse Heart + PRO Badge + Title + Slogan
                      LoginLogoMark(size: logoSize),
                      SizedBox(height: logoToTitleGap),
                      LoginBrandTitle(fontSize: titleSize),
                      SizedBox(height: titleToSloganGap),
                      LoginSlogan(fontSize: sloganSize),
                      SizedBox(height: headerToSwitcherGap),

                      // 2. Tab Switcher: [Đăng nhập] vs [Tạo tài khoản mới]
                      AuthTabSwitcher(
                        isLogin: isLoginMode,
                        onTabChanged: onTabChanged,
                      ),
                      SizedBox(height: switcherToFormGap),

                      // 3. Form Content based on Active Tab
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
                            ? _buildLoginContent(formBlockGap)
                            : _buildRegisterContent(formBlockGap),
                      ),
                    ],
                  ),

                  // App Version note
                  if (appVersion.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: formBlockGap),
                      child: Text(
                        appVersion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildLoginContent(double gap) {
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
        SizedBox(height: gap),

        // Divider
        const LoginDivider('hoặc đăng nhập nhanh qua'),
        SizedBox(height: gap),

        // Social options row (Facebook, TikTok, Zalo, Phone SMS OTP)
        LoginSocialOptionsRow(
          isLoading: isLoading,
          isTikTokLoading: isTikTokLoading,
          isZaloLoading: isZaloLoading,
          onTikTokSignIn: onTikTokSignIn,
          onZaloSignIn: onZaloSignIn,
          onShowPhoneOtpSheet: onShowPhoneOtpSheet,
        ),
        SizedBox(height: gap),

        // Divider
        const LoginDivider('hoặc sử dụng email'),
        SizedBox(height: gap),

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
        SizedBox(height: gap * 0.9),

        // Magic Link Passwordless Card
        MagicLinkCard(onTap: onShowMagicLinkSheet),
      ],
    );
  }

  Widget _buildRegisterContent(double gap) {
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
        SizedBox(height: gap),
      ],
    );
  }
}
