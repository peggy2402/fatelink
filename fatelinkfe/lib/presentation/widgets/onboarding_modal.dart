import 'package:flutter/material.dart';
import 'onboarding/emotion_radar_modal.dart';

class OnboardingModal extends StatelessWidget {
  final VoidCallback onStartChat;
  final VoidCallback? onDismiss;

  const OnboardingModal({
    super.key,
    required this.onStartChat,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return EmotionRadarModal(
      onDismiss: onDismiss ?? onStartChat,
      onStartChat: onStartChat,
    );
  }
}
