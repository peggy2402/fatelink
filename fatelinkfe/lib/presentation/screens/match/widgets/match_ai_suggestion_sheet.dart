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
      backgroundColor: Colors.white,
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
                    radius: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Faye AI gợi ý mở lời:',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...suggestions.map((text) {
              return GestureDetector(
                onTap: () {
                  onSelectSuggestion(text);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE0E7FF),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Color(0xFF334155),
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.touch_app_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
