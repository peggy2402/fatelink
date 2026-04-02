import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:fatelinkfe/widgets/chat_input_bar.dart';
import 'package:fatelinkfe/widgets/floating_ai_bubble.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fatelinkfe/widgets/typing_indicator.dart';

class MatchChatScreen extends StatefulWidget {
  final String partnerName;
  final String partnerId; // Bổ sung ID của partner

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
  final _secureStorage = const FlutterSecureStorage();
  bool _isPartnerTyping = false; // Trạng thái đối phương đang gõ
  // TODO: Khai báo List<ChatMessage> _messages = []; giống hệt bên ChatScreen

  Future<void> _handleUnmatch() async {
    // Hiện dialog loading mờ màn hình
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFBD114A)),
      ),
    );

    try {
      final token = await _secureStorage.read(key: 'accessToken');
      final url = Uri.parse(
        'https://fatelink-be.fly.dev/matches/${widget.partnerId}/unmatch',
      );
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      Navigator.pop(context); // Tắt loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy ghép đôi thành công')),
        );
        // Trở về màn hình trước (MatchesScreen) và trả về "true" để yêu cầu reload danh sách
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể hủy ghép đôi lúc này')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tắt loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối mạng. Vui lòng thử lại!')),
      );
    }
  }

  void _showOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF001520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.orange,
                ),
                title: const Text(
                  'Báo cáo người dùng',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Gọi API Report User
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi báo cáo')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Hủy ghép đôi (Unmatch)',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context); // Đóng BottomSheet
                  // Thực thi logic gọi API
                  _handleUnmatch();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onAiSuggestionTap() {
    // Hiển thị BottomSheet gợi ý câu chat từ AI
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF001520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/images/avt_faye_ai.png',
                    ),
                    radius: 16,
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
              _buildSuggestionChip(
                'Chào cậu, hôm nay của cậu có mệt lắm không?',
              ),
              _buildSuggestionChip(
                'Faye bảo tần số của mình khá hợp nhau, cậu có thích ngắm mưa không?',
              ),
              _buildSuggestionChip(
                'Hi ${widget.partnerName}, cậu có đang nghe bài hát nào hay không share mình với?',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _chatController.text = text;
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  // Widget hiển thị bong bóng chat "Đang gõ..."
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/default_avatar.png'),
            radius: 16,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const TypingIndicator(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001520),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.05),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.partnerName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsBottomSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Khung hiển thị tin nhắn và Typing Indicator
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 120.0),
                  itemCount: _isPartnerTyping
                      ? 1
                      : 0, // Cần cộng thêm _messages.length sau này
                  itemBuilder: (context, index) {
                    // Khi chưa có tin nhắn, chỉ render TypingIndicator nếu isPartnerTyping = true
                    if (_isPartnerTyping) {
                      return _buildTypingIndicator();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),

          // Chat Input Bar ở dưới cùng
          Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputBar(
              controller: _chatController,
              onSend: () {
                _chatController.clear();
              },
              onPlusTap: () {},
              isPopupOpen: false,
            ),
          ),

          // Nút AI Bong bóng trôi nổi
          FloatingAiBubble(
            onTap: _onAiSuggestionTap,
            hasNotification: true, // Chấm đỏ để user biết có thể bấm vào nhờ AI
          ),
        ],
      ),
    );
  }
}
