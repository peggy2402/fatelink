import 'package:flutter/material.dart';

import '../../../../core/utils/toast_utils.dart';

class LoginSocialOptionsRow extends StatelessWidget {
  const LoginSocialOptionsRow({
    super.key,
    required this.isLoading,
    required this.isTikTokLoading,
    required this.isZaloLoading,
    required this.onTikTokSignIn,
    required this.onZaloSignIn,
    required this.onShowPhoneOtpSheet,
  });

  final bool isLoading;
  final bool isTikTokLoading;
  final bool isZaloLoading;
  final VoidCallback onTikTokSignIn;
  final VoidCallback onZaloSignIn;
  final VoidCallback onShowPhoneOtpSheet;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LoginSocialOption(
          assetPath: 'assets/icon/icon-facebook.png',
          isDisabled: isLoading,
          onTap: () => ToastUtil.showInfo(
            context,
            'Facebook login trên app chưa được nối SDK.',
          ),
        ),
        LoginSocialOption(
          assetPath: 'assets/icon/icon-tiktok.png',
          isLoading: isTikTokLoading,
          isDisabled: isLoading && !isTikTokLoading,
          onTap: onTikTokSignIn,
        ),
        LoginSocialOption(
          assetPath: 'assets/icon/icon-zalo.png',
          isLoading: isZaloLoading,
          isDisabled: isLoading && !isZaloLoading,
          onTap: onZaloSignIn,
        ),
        LoginSocialOption(
          assetPath: 'assets/icon/icon-phone.png',
          isDisabled: isLoading,
          onTap: onShowPhoneOtpSheet,
        ),
      ],
    );
  }
}

class LoginSocialOption extends StatelessWidget {
  const LoginSocialOption({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String assetPath;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          InkWell(
            onTap: isDisabled || isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB7D2).withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFFEF3D8B),
                        ),
                      )
                    : Opacity(
                        opacity: isDisabled ? 0.45 : 1,
                        child: Image.asset(
                          assetPath,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
