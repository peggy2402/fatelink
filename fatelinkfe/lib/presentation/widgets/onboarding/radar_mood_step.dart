import 'package:flutter/material.dart';
import 'radar_option_card.dart';

class RadarMoodStep extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String> onSelectMood;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RadarMoodStep({
    super.key,
    required this.selectedMood,
    required this.onSelectMood,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'emoji': '🌙',
        'title': 'Deep Talk',
        'desc': 'Cần được lắng nghe, tâm sự khuya sâu sắc',
        'color': const Color(0xFFA855F7),
      },
      {
        'emoji': '☕',
        'title': 'Chill & Bình yên',
        'desc': 'Không ồn ào, chỉ muốn nhẹ nhàng bình an',
        'color': const Color(0xFF06B6D4),
      },
      {
        'emoji': '🔥',
        'title': 'Hứng khởi & Năng lượng',
        'desc': 'Muốn kết nối, đi chơi, lan tỏa niềm vui',
        'color': const Color(0xFFF43F5E),
      },
      {
        'emoji': '💡',
        'title': 'Tìm tri kỷ & Ý tưởng',
        'desc': 'Cùng tần số tư duy, học tập & sáng tạo',
        'color': const Color(0xFF10B981),
      },
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Badge
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BƯỚC 1 / 3',
                style: TextStyle(
                  color: Color(0xFFFB7185),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        const Text(
          'Hôm nay nhịp đập tâm trạng\ncủa bạn thế nào?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Chọn rung động gần nhất với cảm xúc hiện tại',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 16),

        // List of Options
        ...options.map((opt) {
          final title = opt['title'] as String;
          final isSelected = selectedMood == title;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RadarOptionCard(
              emoji: opt['emoji'] as String,
              title: title,
              description: opt['desc'] as String,
              isSelected: isSelected,
              accentColor: opt['color'] as Color,
              onTap: () => onSelectMood(title),
            ),
          );
        }),

        const SizedBox(height: 8),

        // Next Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: selectedMood != null ? onNext : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: selectedMood != null
                    ? const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFA855F7)],
                      )
                    : null,
                color: selectedMood == null ? Colors.white.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tiếp tục',
                      style: TextStyle(
                        color: selectedMood != null ? Colors.white : Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: selectedMood != null ? Colors.white : Colors.white38,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
