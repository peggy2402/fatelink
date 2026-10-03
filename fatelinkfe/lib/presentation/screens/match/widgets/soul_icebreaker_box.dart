import 'package:flutter/material.dart';

/// Hộp câu hỏi phá băng cảm xúc định mệnh (SoulIcebreakerBox):
/// - Gợi ý câu hỏi sâu sắc để xóa tan cảm giác lúng túng lúc ban đầu
/// - Nút "Chạm để trả lời gợi ý này"
class SoulIcebreakerBox extends StatelessWidget {
  final String question;
  final ValueChanged<String> onSelectPrompt;

  const SoulIcebreakerBox({
    super.key,
    required this.question,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF9D00FF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF9D00FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🌌', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text(
                'CÂU HỎI PHÁ BĂNG ĐỊNH MỆNH',
                style: TextStyle(
                  color: Color(0xFFD896FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onSelectPrompt(question),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF9D00FF).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Chạm để trả lời gợi ý này',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
