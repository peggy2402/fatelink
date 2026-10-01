import 'package:flutter/material.dart';
import 'radar_option_card.dart';

class RadarSignalStep extends StatelessWidget {
  final String? selectedSignal;
  final ValueChanged<String> onSelectSignal;
  final VoidCallback onScan;
  final VoidCallback onBack;

  const RadarSignalStep({
    super.key,
    required this.selectedSignal,
    required this.onSelectSignal,
    required this.onScan,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'emoji': '👂',
        'title': 'Biết lắng nghe chân thành',
        'desc': 'Ấm áp, thấu cảm, không bao giờ phán xét',
        'color': const Color(0xFF10B981),
      },
      {
        'emoji': '☀️',
        'title': 'Tích cực & Hài hước',
        'desc': 'Nụ cười rạng rỡ kéo mình khỏi mọi âu lo',
        'color': const Color(0xFFF59E0B),
      },
      {
        'emoji': '🧩',
        'title': 'Đồng điệu tâm hồn',
        'desc': 'Chỉ cần nhìn mắt là hiểu, cùng gu trò chuyện',
        'color': const Color(0xFFF43F5E),
      },
      {
        'emoji': '🚀',
        'title': 'Bạn đồng hành bứt phá',
        'desc': 'Cùng truyền cảm hứng học tập & phát triển',
        'color': const Color(0xFF6366F1),
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
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BƯỚC 3 / 3',
                style: TextStyle(
                  color: Color(0xFF34D399),
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
          'Tín hiệu bạn đang tìm kiếm\nở người đối diện?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Faye sẽ lọc những người có bước sóng phù hợp nhất',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 16),

        // List of Options
        ...options.map((opt) {
          final title = opt['title'] as String;
          final isSelected = selectedSignal == title;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RadarOptionCard(
              emoji: opt['emoji'] as String,
              title: title,
              description: opt['desc'] as String,
              isSelected: isSelected,
              accentColor: opt['color'] as Color,
              onTap: () => onSelectSignal(title),
            ),
          );
        }),

        const SizedBox(height: 8),

        // Scan Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: selectedSignal != null ? onScan : null,
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
                gradient: selectedSignal != null
                    ? const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFA855F7)],
                      )
                    : null,
                color: selectedSignal == null ? Colors.white.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Bắt đầu Quét Tần Số',
                      style: TextStyle(
                        color: selectedSignal != null ? Colors.white : Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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
