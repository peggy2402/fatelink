import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/core/utils/toast_utils.dart';
import 'package:fatelinkfe/presentation/widgets/typing_indicator.dart';
import 'package:fatelinkfe/data/models/chat_message.dart';
import 'package:fatelinkfe/logic/blocs/chat/chat_bloc.dart';
import 'package:fatelinkfe/logic/blocs/chat/chat_event.dart';
import 'package:fatelinkfe/logic/blocs/chat/chat_state.dart';

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
  final _scrollController = ScrollController();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Kích hoạt nạp lịch sử khi mới vào màn hình
    context.read<ChatBloc>().add(ChatInitializeEvent(context));
  }

  // Hàm gửi tin nhắn để `ChatInputBar` hoặc Modal gọi thông qua GlobalKey (nếu cần)
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatBloc>().add(ChatSendMessageEvent(text.trim()));
  }

  void _showMatchReadyDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001520),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✨ Đã thấu hiểu tâm hồn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        actions: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFBD114A), Color(0xFFD75656)]), borderRadius: BorderRadius.circular(24)),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/matches');
              },
              child: const Text('Khám phá Định mệnh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001520),
      appBar: _buildAppBar(),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          // Xử lý các Effect (Side-effects) 
          if (state.errorMessage.isNotEmpty) {
            ToastUtil.showError(context, state.errorMessage);
          }
          if (state.matchReadyMessage.isNotEmpty) {
            _showMatchReadyDialog(state.matchReadyMessage);
          }
          // Theo dõi có tin nhắn mới thì cuộn + báo cho parent
          if (state.messages.length > _previousMessageCount) {
            _scrollToBottom();
            if (state.messages.isNotEmpty && !state.messages.last.isSentByMe) {
              widget.onNewMessage();
            }
            _previousMessageCount = state.messages.length;
          }
        },
        child: Stack(
          children: [
            _buildBackgroundBlobs(),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.status == ChatStatus.loading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFBD114A)));
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 16.0, bottom: 120.0),
                        itemCount: state.messages.length + (state.showEmotionSuggestions ? 1 : 0) + (state.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < state.messages.length) {
                            return _buildMessageBubble(state.messages[index]);
                          } else if (index == state.messages.length && state.showEmotionSuggestions) {
                            return _buildEmotionSuggestions();
                          } else {
                            return _buildTypingIndicator();
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
