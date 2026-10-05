import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/constants.dart';
import '../../../../services/api_service.dart';

/// BottomSheet gợi ý câu trả lời thông minh từ Faye AI tích hợp trực tiếp backend
class MatchAiSuggestionSheet extends StatefulWidget {
  final String partnerName;
  final String? lastPartnerMessage;
  final List<String>? recentContext;
  final ValueChanged<String> onSelectSuggestion;

  const MatchAiSuggestionSheet({
    super.key,
    required this.partnerName,
    this.lastPartnerMessage,
    this.recentContext,
    required this.onSelectSuggestion,
  });

  static Future<void> show(
    BuildContext context, {
    required String partnerName,
    String? lastPartnerMessage,
    List<String>? recentContext,
    required ValueChanged<String> onSelectSuggestion,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MatchAiSuggestionSheet(
        partnerName: partnerName,
        lastPartnerMessage: lastPartnerMessage,
        recentContext: recentContext,
        onSelectSuggestion: onSelectSuggestion,
      ),
    );
  }

  @override
  State<MatchAiSuggestionSheet> createState() => _MatchAiSuggestionSheetState();
}

class _MatchAiSuggestionSheetState extends State<MatchAiSuggestionSheet> {
  bool _isLoading = true;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadAiSuggestions();
  }

  Future<void> _loadAiSuggestions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${AppConstants.baseUrl}/${AppConstants.suggestReplies}';
      final body = {
        'partnerName': widget.partnerName,
        if (widget.lastPartnerMessage != null &&
            widget.lastPartnerMessage!.trim().isNotEmpty)
          'lastPartnerMessage': widget.lastPartnerMessage!.trim(),
        if (widget.recentContext != null && widget.recentContext!.isNotEmpty)
          'recentContext': widget.recentContext,
      };

      final res = await ApiService.post(url, context, body: body);

      if (res is Map<String, dynamic> && res['suggestions'] is List) {
        final list = (res['suggestions'] as List)
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();

        if (list.isNotEmpty && mounted) {
          setState(() {
            _suggestions = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback thông minh dựa trên ngữ cảnh nếu API có trục trặc mạng
    if (mounted) {
      setState(() {
        _suggestions = _generateContextualFallbacks();
        _isLoading = false;
      });
    }
  }

  List<String> _generateContextualFallbacks() {
    final partner = widget.partnerName;
    final lastMsg = widget.lastPartnerMessage?.toLowerCase() ?? '';

    if (lastMsg.isEmpty) {
      return [
        'Chào $partner, hôm nay của cậu có điều gì làm cậu mỉm cười không? ✨',
        'Faye bảo tần số của hai đứa mình hợp nhau lắm, rất vui được trò chuyện cùng $partner!',
        'Hi $partner, cậu có đang nghe bài hát nào hay ho không share cho mình với nhé?',
        'Chào cậu nè, định mệnh đưa chúng ta gặp nhau ở FateLink hôm nay rồi đó 💫',
      ];
    }

    if (lastMsg.contains('mệt') ||
        lastMsg.contains('oải') ||
        lastMsg.contains('stress') ||
        lastMsg.contains('áp lực')) {
      return [
        'Thương cậu thế, đã về đến nhà nghỉ ngơi chưa hay vẫn đang cày cuốc vậy?',
        'Uống một cốc nước ấm rồi ngả lưng chút đi nè, cần người nghe cậu than thở thì có mình đây nhé!',
        'Hôm nay việc nhiều lắm hả? Để mình truyền chút năng lượng tích cực cho cậu nha ✨',
        'Đi làm/đi học vất vả rồi, tối nay nhớ tự thưởng cho mình món gì ngon ngon nhé!',
      ];
    }

    if (lastMsg.contains('cơm') ||
        lastMsg.contains('ăn') ||
        lastMsg.contains('đói')) {
      return [
        'Mình vừa ăn xong rồi nè, còn cậu đã nạp năng lượng chưa đó?',
        'Hôm nay cậu ăn món gì ngon thế? Gợi ý cho mình với, đang chưa biết ăn gì đây!',
        'Bận mấy cũng phải ăn đúng giờ nha, dạ dày biểu tình là mình phạt đó!',
        'Nhắc đến đồ ăn làm mình cũng thấy đói bụng luôn rồi nè 🍲',
      ];
    }

    if (lastMsg.contains('ngủ') ||
        lastMsg.contains('khuya') ||
        lastMsg.contains('muộn')) {
      return [
        'Cậu cũng là cú đêm giống mình à? Sao giờ này vẫn chưa chịu ngủ thế?',
        'Thức khuya hại sức khoẻ lắm nha, đang lướt mạng hay còn bận gì thế?',
        'Nếu chuẩn bị ngủ thì chúc $partner ngủ thật ngon và có giấc mơ đẹp nhé ✨',
        'Cậu hay thức muộn thế này à? Mai không phải dậy sớm hả cậu?',
      ];
    }

    return [
      'Nghe cậu kể thú vị ghê, kể thêm cho mình nghe đoạn sau với nào!',
      'Cậu nói chuẩn gu mình luôn đấy, tự nhiên thấy nói chuyện với cậu hợp phết ✨',
      'Haha thế á, cậu làm mình tò mò muốn biết nhiều hơn về cậu rồi đấy nhé!',
      'Công nhận luôn! Mà bình thường cậu cũng hay để ý mấy điều tinh tế thế này hả?',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasLastMessage = widget.lastPartnerMessage != null &&
        widget.lastPartnerMessage!.trim().isNotEmpty;

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

            // Header: Avatar Faye AI + Tiêu đề + Nút Làm mới gợi ý
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLastMessage
                            ? 'Faye AI gợi ý câu trả lời:'
                            : 'Faye AI gợi ý mở lời:',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: Color(0xFF0F172A),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        hasLastMessage
                            ? 'Tự động phản hồi tin nhắn của ${widget.partnerName}'
                            : 'Bắt đầu cuộc trò chuyện tự nhiên',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isLoading)
                  IconButton(
                    tooltip: 'Đổi câu gợi ý khác',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 22,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _loadAiSuggestions();
                    },
                  ),
              ],
            ),

            // Hộp trích dẫn tin nhắn gần nhất của đối phương
            if (hasLastMessage) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEDE9FE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(
                        Icons.format_quote_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${widget.partnerName}: ',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                            TextSpan(
                              text: '"${widget.lastPartnerMessage}"',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Danh sách gợi ý hoặc trạng thái đang tải
            if (_isLoading)
              ...List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Faye AI đang suy nghĩ câu trả lời phù hợp...',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Color(0xFF94A3B8),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._suggestions.map((text) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSelectSuggestion(text);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  color: Color(0xFF334155),
                                  fontSize: 13.5,
                                  height: 1.42,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.touch_app_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 19,
                            ),
                          ],
                        ),
                      ),
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
