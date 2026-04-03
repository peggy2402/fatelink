import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fatelinkfe/utils/toast_utils.dart';
import 'package:fatelinkfe/widgets/typing_indicator.dart';

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
  final VoidCallback onBack;
  final VoidCallback onNewMessage;

  const ChatScreen({
    super.key,
    required this.onBack,
    required this.onNewMessage,
  });

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  // Dữ liệu giả để dựng giao diện
  final List<ChatMessage> _messages = [
    // Dữ liệu giả này sẽ được thay thế bằng API
    /* ChatMessage(
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
    ), */
  ];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _secureStorage = const FlutterSecureStorage();
  late IO.Socket _socket;
  bool _isTyping = false; // Trạng thái AI đang xử lý
  bool _isLoadingHistory = true; // Thêm biến trạng thái loading
  bool _isInputEmpty = true; // Theo dõi trạng thái rỗng của input
  bool _showEmotionSuggestions = false; // Biến hiển thị gợi ý cảm xúc

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final token = await _secureStorage.read(key: 'accessToken');
    await _loadChatHistory(token);
    if (token != null) _connectToSocket(token);
  }

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);
      return data['sub'] ?? data['id'] ?? data['userId'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadChatHistory(String? token) async {
    if (token == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }
    try {
      final userId = _getUserIdFromToken(token);
      if (userId == null) throw Exception('Token không hợp lệ');

      final url = Uri.parse(
        'https://fatelink-be.fly.dev/messages/$userId?limit=50',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          // Nếu lịch sử trống, hiển thị câu chào mặc định và bật gợi ý cảm xúc
          setState(() {
            _messages.add(
              ChatMessage(
                text: "Hôm nay tâm trạng của bạn đang như thế nào? 🍂",
                isSentByMe: false,
                timestamp: DateTime.now(),
              ),
            );
            _showEmotionSuggestions = true;
          });
        } else {
          final history = data
              .map(
                (msg) => ChatMessage(
                  text: msg['text'],
                  isSentByMe: msg['isSentByMe'],
                  timestamp: DateTime.parse(msg['timestamp']).toLocal(),
                ),
              )
              .toList();
          setState(() => _messages.addAll(history));
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải lịch sử chat: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _connectToSocket(String token) {
    // LƯU Ý: Đổi URL này cho khớp với backend của bạn
    // Môi trường thật: 'https://fatelink-be.fly.dev'
    // Môi trường test (máy ảo Android): 'http://10.0.2.2:3000'
    const String socketUrl = 'https://fatelink-be.fly.dev';

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Bắt buộc dùng websocket
          .disableAutoConnect() // Tắt tự động kết nối để quản lý thủ công
          .setAuth({'token': token})
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
        widget.onNewMessage(); // Báo cho MainScreen biết có tin nhắn mới
      }
    });

    _socket.on('errorMessage', (data) {
      if (mounted) {
        setState(() => _isTyping = false);
        ToastUtil.showError(context, data['message']);
      }
    });

    // Bắt sự kiện khi AI báo đã sẵn sàng ghép cặp (Kích hoạt Phase 2)
    _socket.on('matchReady', (data) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF001520),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '✨ Đã thấu hiểu tâm hồn',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              data['message'] ??
                  'Faye đã hiểu rõ bạn là người thế nào. Hãy cùng xem ai là người đang tìm kiếm một tâm hồn như bạn nhé!',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            actions: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBD114A), Color(0xFFD75656)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng Dialog
                    // Đẩy sang màn hình Danh sách những người hợp nhau
                    Navigator.pushReplacementNamed(context, '/matches');
                  },
                  child: const Text(
                    'Khám phá Định mệnh',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Kiểm tra kết nối trước khi gửi
    if (!_socket.connected) {
      ToastUtil.showError(
        context,
        "Mất kết nối máy chủ. Đang thử kết nối lại...",
      );
      _socket.connect();
      return;
    }

    final userMessage = ChatMessage(
      text: text.trim(),
      isSentByMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _showEmotionSuggestions = false; // Tắt nút gợi ý khi user đã gửi tin
      _isTyping = true; // Bật trạng thái AI đang gõ
    });
    _scrollToBottom();

    // Gửi tin nhắn lên server
    _socket.emit('sendMessage', {'text': userMessage.text});

    // Timeout an toàn: Tự động tắt typing sau 15 giây nếu server không phản hồi
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isTyping) {
        setState(() => _isTyping = false);
        ToastUtil.showError(
          context,
          "Mạng yếu hoặc Faye đang bận. Vui lòng thử lại!",
        );
      }
    });
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
                        padding: const EdgeInsets.only(
                          top: 16.0,
                          bottom: 120.0,
                        ), // Tạo khoảng trống để không bị che bởi ChatInputBar nổi
                        itemCount:
                            _messages.length +
                            (_showEmotionSuggestions ? 1 : 0) +
                            (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            return _buildMessageBubble(_messages[index]);
                          } else if (index == _messages.length &&
                              _showEmotionSuggestions) {
                            return _buildEmotionSuggestions(); // Hiện nút cảm xúc
                          } else {
                            return _buildTypingIndicator();
                          }
                        },
                      ),
                    ),
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
              onPressed: widget.onBack, // Gọi hàm onBack từ MainScreen
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
              color: Color(0xFF0066FF), // Đổi blob đỏ thành xanh dương
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
        : const Color(
            0xFF0D47A1,
          ).withOpacity(0.6); // Đổi màu bong bóng AI sang xanh đậm
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
              color: const Color(
                0xFF0D47A1,
              ).withOpacity(0.6), // Đổi màu sang xanh đậm
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
            child: const TypingIndicator(), // Sử dụng widget mới
          ),
        ],
      ),
    );
  }

  // Widget hiển thị danh sách gợi ý cảm xúc cho người dùng chọn nhanh
  Widget _buildEmotionSuggestions() {
    final emotions = ['Bình yên 🍃', 'Áp lực 🌪️', 'Cô đơn 🌧️', 'Vui vẻ ✨'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.end,
        children: emotions
            .map(
              (emotion) => ActionChip(
                backgroundColor: Colors.white.withOpacity(0.1),
                side: BorderSide(
                  color: const Color(0xFF0D47A1).withOpacity(0.5),
                ),
                label: Text(
                  emotion,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  sendMessage(emotion); // Gửi tin nhắn đi khi bấm
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
