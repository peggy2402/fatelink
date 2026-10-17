import 'package:flutter/material.dart';
import '../../../widgets/typing_indicator.dart';

class MatchTypingIndicator extends StatelessWidget {
  final LinearGradient auraGradient;
  final Widget partnerAvatarWidget;

  const MatchTypingIndicator({
    super.key,
    required this.auraGradient,
    required this.partnerAvatarWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: auraGradient,
            ),
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: partnerAvatarWidget,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TypingIndicator(color: Color(0xFF8B5CF6)),
          ),
        ],
      ),
    );
  }
}
