import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fatelinkfe/presentation/widgets/back.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/presentation/widgets/typing_indicator.dart';
import 'package:fatelinkfe/data/models/chat_message.dart';
import 'package:fatelinkfe/logic/blocs/chat/chat_bloc.dart';
import 'package:fatelinkfe/logic/blocs/chat/chat_event.dart';
import 'package:fatelinkfe/logic/blocs/chat/chat_state.dart';
import 'package:easy_localization/easy_localization.dart';

// Enum để quản lý 2 chế độ xem
enum ChatView { list, room }

class ChatScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNewMessage;
  final Function(ChatView) onViewChanged;

  const ChatScreen({
    super.key,
    required this.onBack,
    required this.onNewMessage,
    required this.onViewChanged,
  });

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  ChatView _currentView = ChatView.list;
  final _scrollController = ScrollController();
  final _chatController = TextEditingController();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatInitializeEvent(context));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // Đổi thành public để MainScreen có thể gọi qua GlobalKey
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatBloc>().add(ChatSendMessageEvent(text.trim()));
    _chatController.clear();
    _scrollToBottom();
  }

  void _switchToRoomView() {
    setState(() => _currentView = ChatView.room);
    _scrollToBottom(animated: false); // Cuộn xuống ngay khi chuyển view
    widget.onViewChanged(ChatView.room);
  }

  void _switchToListView() {
    setState(() => _currentView = ChatView.list);
    widget.onViewChanged(ChatView.list);
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng AnimatedSwitcher để tạo hiệu ứng chuyển cảnh mượt mà
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _currentView == ChatView.list
          ? _buildChatListView()
          : _buildChatRoomView(),
    );
  }

  // --- WIDGETS CHO MÀN HÌNH DANH SÁCH CHAT ---

  Widget _buildChatListView() {
    return Scaffold(
      key: const ValueKey('ChatListView'),
      backgroundColor: const Color(0xFFF8F9FA), // Nền sáng
      body: CustomScrollView(
        slivers: [
          _buildListAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildOnlineStatusList()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),
          ),
          _buildConversationList(),
        ],
      ),
    );
  }

  SliverAppBar _buildListAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF8F9FA),
      pinned: true,
      expandedHeight: 120.0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'Trò chuyện',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        _buildAppBarIcon(Icons.search),
        _buildAppBarIcon(Icons.add),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Icon(icon, color: Colors.grey.shade600, size: 22),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tin nhắn...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildOnlineStatusList() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10, // Faye AI + 9 users
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildOnlineAvatar(
              name: 'Faye AI',
              imageUrl: 'assets/images/avt_faye_ai.png',
              isBot: true,
            );
          }
          return _buildOnlineAvatar(
            name: 'User ${index + 1}',
            imageUrl: 'assets/images/default_avatar.png',
          );
        },
      ),
    );
  }

  Widget _buildOnlineAvatar({
    required String name,
    required String imageUrl,
    bool isBot = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isBot
                      ? const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFFFF69B4)])
                      : null,
                  color: isBot ? null : Colors.grey.shade300,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage(imageUrl),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
              if (isBot)
                Positioned(
                  top: -4,
                  left: -4,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFF9C27B0),
                    child:
                        Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  SliverList _buildConversationList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Chỉ hiển thị cuộc trò chuyện với Faye AI
          return _buildConversationItem(
            name: 'Faye AI',
            imageUrl: 'assets/images/avt_faye_ai.png',
            lastMessage: 'Chào bạn, hôm nay của bạn thế nào?',
            time: '10:36',
            unreadCount: 1,
            isBot: true,
            onTap: _switchToRoomView,
          );
        },
        childCount: 1,
      ),
    );
  }

  Widget _buildConversationItem({
    required String name,
    required String imageUrl,
    required String lastMessage,
    required String time,
    int unreadCount = 0,
    bool isBot = false,
    required VoidCallback onTap,
  }) {
    final bool hasUnread = unreadCount > 0;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: hasUnread ? Colors.cyan.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildOnlineAvatar(name: '', imageUrl: imageUrl, isBot: isBot),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.normal,
                      color: hasUnread
                          ? Colors.grey.shade800
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread
                        ? const Color(0xFF00B8D4)
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                if (hasUnread)
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFFF3B30),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS CHO MÀN HÌNH PHÒNG CHAT ---

  Widget _buildChatRoomView() {
    return Scaffold(
      key: const ValueKey('ChatRoomView'),
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildRoomAppBar(),
      body: BlocListener<ChatBloc, ChatState>(
        listenWhen: (previous, current) {
          return previous.messages.length != current.messages.length || previous.isTyping != current.isTyping;
        },
        listener: (context, state) {
          _scrollToBottom();
          if (state.messages.length > _previousMessageCount) {
            if (state.messages.isNotEmpty && !state.messages.last.isSentByMe) {
              widget.onNewMessage();
            }
            _previousMessageCount = state.messages.length;
          }
        },
        child: Stack(
          children: [
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.status == ChatStatus.loading &&
                    state.messages.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFBD114A)));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Lật ngược danh sách (rất quan trọng)
                  padding: const EdgeInsets.only(top: 100.0, bottom: 16.0), // Padding cũng được đổi ngược lại
                  itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (state.isTyping) {
                      if (index == 0) return _buildRoomTypingIndicator(); // Khi gõ, bong bóng nằm kề đáy
                      final msgIndex = state.messages.length - index;
                      return _buildRoomMessageBubble(state.messages[msgIndex]);
                    } else {
                      final msgIndex = state.messages.length - 1 - index;
                      return _buildRoomMessageBubble(state.messages[msgIndex]);
                    }
                  },
                );
              },
            ),
            // Input bar is now handled by MainScreen
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildRoomAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.75),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: CustomBackButton(onPressed: _switchToListView),
            ),
            leadingWidth: 60, // Tăng không gian cho nút back
            title: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Faye AI',
                            style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF9C27B0), Color(0xFF00B8D4)]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BOT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    Text('Đang hoạt động...',
                        style: TextStyle(
                            color: Colors.green.shade600, fontSize: 12)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget bong bóng chat
  Widget _buildRoomMessageBubble(ChatMessage message) {
    final isMe = message.isSentByMe;

    // Định dạng giờ phút (VD: 09:05)
    final timeString =
        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
              radius: 14,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.blueGrey.shade700.withOpacity(0.6)
                        : null,
                    gradient: isMe
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                      bottomRight:
                          isMe ? Radius.zero : const Radius.circular(20),
                    ),
                    boxShadow: isMe
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF1E40AF).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  child: Text(
                    message.text,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
              backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
              radius: 14),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20)
                    .copyWith(bottomLeft: Radius.zero)),
            child: const TypingIndicator(),
          ),
        ],
      ),
    );
  }
}
