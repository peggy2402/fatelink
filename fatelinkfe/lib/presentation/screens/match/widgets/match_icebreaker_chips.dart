import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MatchIcebreakerChips extends StatelessWidget {
  final List<String> icebreakers;
  final ValueChanged<String> onSelectPrompt;

  const MatchIcebreakerChips({
    super.key,
    required this.icebreakers,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    if (icebreakers.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: icebreakers.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = icebreakers[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onSelectPrompt(prompt);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E7FF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFF334155),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
