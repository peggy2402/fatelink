import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fatelinkfe/utils/toast_utils.dart';

// Model đơn giản để chứa dữ liệu của một tin nhắn
class ChatMessage {
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Dữ liệu giả để dựng giao diện
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Chào bạn, mình là Faye. Hôm nay của bạn thế nào?",
      isSentByMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ChatMessage(
      text: "Chào Faye, hôm nay mình cũng bình thường thôi.",
      isSentByMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    ChatMessage(
      text:
          "“Bình thường” à? Nghe có vẻ như có một chút gì đó chưa được tỏ bày hết nhỉ 😏",
      isSentByMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
    ),
    ChatMessage(
      text: "Haha, tinh ý thật đấy.",
      isSentByMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late IO.Socket _socket;
  bool _isTyping = false; // Trạng thái AI đang xử lý
  bool _isLoadingHistory = false; // Thêm biến trạng thái loading

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    // LƯU Ý: Đổi URL này cho khớp với backend của bạn
    // Môi trường thật: 'https://fatelink-production.up.railway.app'
    // Môi trường test (máy ảo Android): 'http://10.0.2.2:3000'
    const String socketUrl = 'https://fatelink-production.up.railway.app';

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Bắt buộc dùng websocket
          .disableAutoConnect() // Tắt tự động kết nối để quản lý thủ công
          .build(),
    );

    _socket.connect();

    // Lắng nghe các sự kiện từ server
    _socket.onConnect((_) => debugPrint('✅ Socket connected'));
    _socket.onDisconnect((_) => debugPrint('❌ Socket disconnected'));

    _socket.on('receiveMessage', (data) {
      final message = ChatMessage(
        text: data['text'],
        isSentByMe: false,
        timestamp: DateTime.parse(data['timestamp']).toLocal(),
      );
      if (mounted) {
        setState(() {
          _messages.add(message);
          _isTyping = false; // Tắt trạng thái đang gõ
        });
        _scrollToBottom();
      }
    });

    _socket.on('errorMessage', (data) {
      if (mounted) {
        setState(() => _isTyping = false);
        ToastUtil.showError(context, data['message']);
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isSentByMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true; // Bật trạng thái AI đang gõ
    });
    _textController.clear();
    _scrollToBottom();

    // Gửi tin nhắn lên server
    _socket.emit('sendMessage', {'text': userMessage.text});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socket.dispose(); // Ngắt kết nối socket khi màn hình bị hủy
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001520),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Nền blobs mờ ảo kế thừa từ WelcomeScreen
          _buildBackgroundBlobs(),
          _isLoadingHistory
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBD114A)),
                )
              : Column(
                  children: [
                    // Danh sách tin nhắn
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return _buildTypingIndicator(); // Widget hiển thị "Đang gõ"
                          }
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
                    ),
                    // Khung nhập liệu
                    _buildInputArea(),
                  ],
                ),
        ],
      ),
    );
  }

  // AppBar tùy chỉnh với hiệu ứng Glassmorphism
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.05),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Faye AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'đang hoạt động...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onPressed: () {
                  // TODO: Implement more options
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget nền blobs
  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -150,
          child: Container(
            width: 350,
            height: 350,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFBD114A),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox(),
          ),
        ),
      ],
    );
  }

  // Widget bong bóng chat
  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isSentByMe;
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bubbleColor = isMe
        ? Colors.white.withOpacity(0.15)
        : const Color(0xFFBD114A).withOpacity(0.4);
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    // Định dạng giờ phút (VD: 09:05)
    final timeString =
        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị trạng thái AI đang gõ
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
            radius: 16,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFBD114A).withOpacity(0.4),
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
            child: Text(
              'Faye đang suy nghĩ...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget khung nhập liệu
  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nhắn tin cho Faye...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (text) {
                      _sendMessage(text);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFFBD114A),
                    size: 28,
                  ),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
