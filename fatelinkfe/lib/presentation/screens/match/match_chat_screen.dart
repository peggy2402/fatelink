import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/models/chat_message.dart';
import '../../../presentation/widgets/chat_input_bar.dart';
import '../../../presentation/widgets/typing_indicator.dart';
import '../../../services/api_service.dart';

// Components tách rời sạch sẽ
import '../../widgets/cosmic_report_modal.dart';
import 'widgets/match_ai_suggestion_sheet.dart';
import 'widgets/match_options_bottom_sheet.dart';

/// Màn hình trò chuyện giữa 2 người dùng đã ghép đôi (MatchChatScreen):
/// - Giao diện Cosmic Dark sang trọng, đồng bộ với chủ đề định mệnh của FateLink
/// - Bố cục Column chuẩn mực: ChatInputBar luôn cố định ở đáy, không bao giờ bị nhảy lên giữa
/// - Tắt hoàn toàn hàng chip bot Faye AI, hiển thị đúng hintText cho người đối diện
/// - Nút gợi ý câu mở lời từ Faye AI (AutoAwesome) thông minh
class MatchChatScreen extends StatefulWidget {
  final String partnerName;
  final String partnerId;

  const MatchChatScreen({
    super.key,
    required this.partnerName,
    required this.partnerId,
  });

  @override
  State<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends State<MatchChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _secureStorage = SecureStorageHelper.storage;

  bool _isPartnerTyping = false;
  final List<ChatMessage> _messages = [];
  bool _isNearBottom = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Tin nhắn mở đầu từ hệ thống/đối phương
    _messages.add(
      ChatMessage(
        text: 'Xin chào! Rất vui vì định mệnh đã kết nối chúng ta hôm nay ✨',
        isSentByMe: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final isNearBottom = _scrollController.offset <= 100.0;
    if (_isNearBottom != isNearBottom) {
      setState(() => _isNearBottom = isNearBottom);
    }
    if (isNearBottom && _unreadCount > 0) {
      setState(() => _unreadCount = 0);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleUnmatch() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (!mounted) return;
      final url = '${AppConstants.baseUrl}/matches/${widget.partnerId}/unmatch';

      await ApiService.delete(url, context, token: token, showLoading: true);

      if (!mounted) return;
      ToastUtil.showSuccess(context, 'Đã hủy ghép đôi thành công');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Lỗi kết nối mạng. Vui lòng thử lại!');
    }
  }

  Future<void> _handleBlockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text(
              'Chặn người dùng?',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn chặn ${widget.partnerName}? Người này sẽ bị xóa khỏi danh sách bạn bè và không thể tìm thấy, gửi sóng hay trò chuyện với bạn nữa.',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Chặn vĩnh viễn',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (!mounted) return;
      final url =
          '${AppConstants.baseUrl}/${AppConstants.userBlock(widget.partnerId)}';
      await ApiService.post(url, context, token: token, showLoading: true);

      if (!mounted) return;
      ToastUtil.showSuccess(
          context, 'Đã chặn ${widget.partnerName} thành công');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Lỗi thao tác chặn. Vui lòng thử lại!');
    }
  }

  void _showOptionsModal() {
    MatchOptionsBottomSheet.show(
      context,
      onReport: () {
        Navigator.pop(context);
        CosmicReportModal.show(
          context,
          targetUserId: widget.partnerId,
          targetUserName: widget.partnerName,
          onReported: (blocked) {
            if (blocked && mounted) {
              Navigator.pop(context, true);
            }
          },
        );
      },
      onUnmatch: () {
        Navigator.pop(context);
        _handleUnmatch();
      },
      onBlock: () {
        Navigator.pop(context);
        _handleBlockUser();
      },
    );
  }

  void _showAiSuggestionModal() {
    MatchAiSuggestionSheet.show(
      context,
      partnerName: widget.partnerName,
      onSelectSuggestion: (text) {
        _chatController.text = text;
      },
    );
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: text.trim(),
          isSentByMe: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _chatController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Giả lập phản hồi từ đối phương sau 2.5s
    _simulatePartnerReply();
  }

  void _simulatePartnerReply() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isPartnerTyping = true);

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        setState(() {
          _isPartnerTyping = false;
          _messages.insert(
            0,
            ChatMessage(
              text: 'Cảm ơn tin nhắn của bạn nhé! Mình vừa đọc được rồi nè ❤️',
              isSentByMe: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1326),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.partnerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF00FFB2), size: 8),
                SizedBox(width: 4),
                Text(
                  'Đang trực tuyến',
                  style: TextStyle(color: Color(0xFF00FFB2), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Nút AI gợi ý mở lời thông minh
          IconButton(
            tooltip: 'Faye AI gợi ý câu mở lời',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF00F0FF), size: 22),
            onPressed: _showAiSuggestionModal,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: _showOptionsModal,
          ),
        ],
      ),
      // Bố cục Column chuẩn mực: Đảm bảo ChatInputBar LUÔN bám sát foot điện thoại
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Khung hiển thị tin nhắn và Typing Indicator
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    itemCount: _messages.length + (_isPartnerTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isPartnerTyping) {
                        if (index == 0) return _buildTypingIndicator();
                        return _buildMessageBubble(_messages[index - 1]);
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),

                  // Nút cuộn xuống dưới cùng khi có tin nhắn mới
                  if (!_isNearBottom)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: GestureDetector(
                        onTap: () {
                          _scrollToBottom();
                          setState(() => _unreadCount = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B30),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Thanh ChatInputBar chuẩn tối, không có chips bot Faye AI
            ChatInputBar(
              controller: _chatController,
              showQuickChips: false, // TẮT CHIPS BOT FAYE AI
              isDark: true,          // THEME TỐI ĐỒNG BỘ
              hintText: 'Nhắn tin cho ${widget.partnerName}...',
              onSubmitted: _handleSendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isSentByMe;
    final timeString =
        "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFFFF2A6D), Color(0xFFFF5E97)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF1E2640), Color(0xFF161C30)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: isMe
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                timeString,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF161C30),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const TypingIndicator(),
        ),
      ),
    );
  }
}
