import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/constants.dart';

class LoginSupportButton extends StatelessWidget {
  const LoginSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          launchUrl(
            Uri.parse('${AppConstants.serverUrl}${AppConstants.support}'),
          );
        },
        icon: const Icon(Icons.headset_mic_outlined, size: 16),
        label: const Text('Hỗ trợ'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFEF3D8B),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class LoginLogoMark extends StatelessWidget {
  const LoginLogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA7C9).withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF4E95), Color(0xFFFF5B47)],
            ),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            size: 54,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class LoginBrandTitle extends StatelessWidget {
  const LoginBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [Color(0xFFB82060), Color(0xFF69255F)],
        ).createShader(bounds);
      },
      child: const Text(
        'FateLink',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
