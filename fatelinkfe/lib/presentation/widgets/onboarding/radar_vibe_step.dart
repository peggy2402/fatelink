import 'package:flutter/material.dart';
import 'radar_option_card.dart';

class RadarVibeStep extends StatelessWidget {
  final String? selectedVibe;
  final ValueChanged<String> onSelectVibe;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RadarVibeStep({
    super.key,
    required this.selectedVibe,
    required this.onSelectVibe,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'emoji': '🌧️',
        'title': 'Ban công ngắm mưa',
        'desc': 'Tiếng mưa rơi êm đềm, đắm trong giai điệu Lofi',
        'color': const Color(0xFF3B82F6),
      },
      {
        'emoji': '🎷',
        'title': 'Quán Cafe Indie',
        'desc': 'Hương cà phê ấm cúng, nốt nhạc Jazz dìu dặt',
        'color': const Color(0xFFF59E0B),
      },
      {
        'emoji': '🌅',
        'title': 'Bờ biển hoàng hôn',
        'desc': 'Gió biển lộng, ngắm hoàng hôn tím hồng',
        'color': const Color(0xFFEC4899),
      },
      {
        'emoji': '🌃',
        'title': 'Tầng thượng phố đêm',
        'desc': 'Ngắm thành phố lung linh ánh đèn từ trên cao',
        'color': const Color(0xFF8B5CF6),
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
                color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BƯỚC 2 / 3',
                style: TextStyle(
                  color: Color(0xFFC084FC),
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
          'Không gian lý tưởng để\nbạn trốn cả thế giới?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Giúp Faye hình dung bối cảnh tâm hồn của bạn',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 16),

        // List of Options
        ...options.map((opt) {
          final title = opt['title'] as String;
          final isSelected = selectedVibe == title;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RadarOptionCard(
              emoji: opt['emoji'] as String,
              title: title,
              description: opt['desc'] as String,
              isSelected: isSelected,
              accentColor: opt['color'] as Color,
              onTap: () => onSelectVibe(title),
            ),
          );
        }),

        const SizedBox(height: 8),

        // Next Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: selectedVibe != null ? onNext : null,
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
                gradient: selectedVibe != null
                    ? const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFA855F7)],
                      )
                    : null,
                color: selectedVibe == null ? Colors.white.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tiếp tục',
                      style: TextStyle(
                        color: selectedVibe != null ? Colors.white : Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: selectedVibe != null ? Colors.white : Colors.white38,
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
