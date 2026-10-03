import 'package:flutter/material.dart';

/// BottomSheet gợi ý mở lời từ Faye AI khi chat với bạn bè (MatchAiSuggestionSheet)
class MatchAiSuggestionSheet extends StatelessWidget {
  final String partnerName;
  final ValueChanged<String> onSelectSuggestion;

  const MatchAiSuggestionSheet({
    super.key,
    required this.partnerName,
    required this.onSelectSuggestion,
  });

  static Future<void> show(
    BuildContext context, {
    required String partnerName,
    required ValueChanged<String> onSelectSuggestion,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MatchAiSuggestionSheet(
        partnerName: partnerName,
        onSelectSuggestion: onSelectSuggestion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Chào cậu, hôm nay của cậu có mệt lắm không?',
      'Faye bảo tần số của mình khá hợp nhau, cậu có thích ngắm hoàng hôn không?',
      'Hi $partnerName, cậu có đang nghe bài hát nào hay không share mình với?',
      'Chào $partnerName, rất vui vì định mệnh đã kết nối chúng ta hôm nay ✨',
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
                  radius: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Faye gợi ý mở lời:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions.map((text) {
            return GestureDetector(
              onTap: () {
                onSelectSuggestion(text);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                      ),
                    ),
                    const Icon(Icons.touch_app_rounded, color: Color(0xFF00E5FF), size: 16),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
