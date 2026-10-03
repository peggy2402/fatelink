import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/blocs/chat/chat_bloc.dart';
import '../../../logic/blocs/chat/chat_event.dart';
import '../../../logic/blocs/chat/chat_state.dart';

// Components tách rời sạch sẽ
import 'widgets/chat_conversation_tile.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_online_stories.dart';
import 'widgets/chat_room_app_bar.dart';
import 'widgets/chat_typing_indicator_bubble.dart';
import '../match/cosmic_broadcast_screen.dart';
import '../home/widgets/radar_scanner_modal.dart';

// Enum để quản lý 2 chế độ xem: Danh sách hoặc Phòng trò chuyện
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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int _previousMessageCount = 0;
  bool _isNearBottom = true;
  int _unreadCount = 0;
  bool _isSearchOpen = false;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'ai', 'unread'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    context.read<ChatBloc>().add(ChatInitializeEvent(context));
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // Nhận diện khi người dùng ở sát đáy (dưới 100px)
    final isNearBottom = _scrollController.offset <= 100.0;
    if (_isNearBottom != isNearBottom) {
      setState(() => _isNearBottom = isNearBottom);
    }

    if (isNearBottom && _unreadCount > 0) {
      setState(() => _unreadCount = 0);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _switchToRoomView() {
    setState(() => _currentView = ChatView.room);
    _scrollToBottom(animated: false);
    widget.onViewChanged(ChatView.room);
  }

  void _switchToListView() {
    setState(() => _currentView = ChatView.list);
    widget.onViewChanged(ChatView.list);
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0.0);
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  /// Hiển thị Menu hành động nhanh khi người dùng bấm dấu "+" trên AppBar
  void _showNewChatActionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Khởi tạo kết nối mới',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Lựa chọn phương thức kết nối và giao lưu tần số cùng người khác',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),

              // 1. Trò chuyện cùng Faye AI
              _buildActionItem(
                icon: Icons.psychology_rounded,
                color: const Color(0xFF6366F1),
                title: 'Tâm sự cùng Trợ lý Faye AI',
                subtitle: 'Giải tỏa cảm xúc, lắng nghe và thấu cảm 24/7',
                onTap: () {
                  Navigator.pop(ctx);
                  _switchToRoomView();
                },
              ),
              const SizedBox(height: 12),

              // 2. Phát sóng tần số 432Hz
              _buildActionItem(
                icon: Icons.podcasts_rounded,
                color: const Color(0xFFEC4899),
                title: 'Phát sóng tần số 432Hz',
                subtitle: 'Tìm người cùng gu tần số trong 120 giây',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CosmicBroadcastScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 3. Quét Radar tâm trạng
              _buildActionItem(
                icon: Icons.radar_rounded,
                color: const Color(0xFF10B981),
                title: 'Quét Radar đo lường cảm xúc',
                subtitle: 'Khám phá các linh hồn đang đồng điệu xung quanh',
                onTap: () {
                  Navigator.pop(ctx);
                  RadarScannerModal.show(
                    context,
                    onConnectMatch: () => Navigator.of(context).pushNamed('/matches'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

  // ==========================================
  // 1. GIAO DIỆN DANH SÁCH CUỘC TRÒ CHUYỆN
  // ==========================================

  Widget _buildChatListView() {
    return Scaffold(
      key: const ValueKey('ChatListView'),
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildListAppBar(),
          if (_isSearchOpen)
            SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(
            child: ChatOnlineStories(onFayeTap: _switchToRoomView),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildFilterChips(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      elevation: 0,
      expandedHeight: 96.0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: const Text(
          'Trò chuyện',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.4,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          tooltip: 'Tìm kiếm tin nhắn',
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _isSearchOpen
                  ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: _isSearchOpen ? const Color(0xFF6366F1) : const Color(0xFF475569),
              size: 19,
            ),
          ),
        ),
        IconButton(
          onPressed: _showNewChatActionModal,
          tooltip: 'Bắt đầu kết nối mới',
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 19),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildChip('all', 'Tất cả'),
        const SizedBox(width: 8),
        _buildChip('ai', 'Trợ lý AI Faye 🤖'),
        const SizedBox(width: 8),
        _buildChip('unread', 'Chưa đọc 💬'),
      ],
    );
  }

  Widget _buildChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 14,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Tìm cuộc trò chuyện hoặc người đồng điệu...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  SliverList _buildConversationList() {
    // Lọc theo search và category filter
    final bool matchFaye = _searchQuery.isEmpty ||
        'faye ai'.contains(_searchQuery.toLowerCase()) ||
        'chào bạn, hôm nay của bạn thế nào?'.contains(_searchQuery.toLowerCase());

    final bool showFaye = matchFaye && (_selectedFilter == 'all' || _selectedFilter == 'ai' || _selectedFilter == 'unread');

    if (!showFaye) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF6366F1)),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Không tìm thấy cuộc trò chuyện nào',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hãy thử tìm kiếm với từ khóa khác hoặc bấm dấu "+" để tạo kết nối mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Cuộc trò chuyện với trợ lý Faye AI
          return ChatConversationTile(
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

  // ==========================================
  // 2. GIAO DIỆN PHÒNG CHAT VỚI FAYE AI
  // ==========================================

  Widget _buildChatRoomView() {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: const ValueKey('ChatRoomView'),
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: ChatRoomAppBar(
        onBack: _switchToListView,
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listenWhen: (previous, current) {
          return previous.messages.length != current.messages.length ||
              previous.isTyping != current.isTyping;
        },
        listener: (context, state) {
          if (state.messages.length > _previousMessageCount) {
            final newMessage = state.messages.last;
            final isMe = newMessage.isSentByMe;

            if (isMe || _isNearBottom) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            } else {
              setState(() => _unreadCount += (state.messages.length - _previousMessageCount));
            }

            if (!isMe) {
              widget.onNewMessage();
            }
            _previousMessageCount = state.messages.length;
          } else if (state.isTyping && _isNearBottom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        },
        child: Stack(
          children: [
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.status == ChatStatus.loading && state.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF2A6D)),
                  );
                }

                // Chừa bottom padding = 155.0 + bottomSafe để tin nhắn cuối cùng hoàn toàn
                // nằm TRÊN thanh gợi ý và input bar, triệt tiêu 100% lỗi bị che khuất!
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.only(
                    top: 24.0,
                    bottom: bottomSafe + 155.0,
                  ),
                  itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (state.isTyping) {
                      if (index == 0) return const ChatTypingIndicatorBubble();
                      final msgIndex = state.messages.length - index;
                      return ChatMessageBubble(message: state.messages[msgIndex]);
                    } else {
                      final msgIndex = state.messages.length - 1 - index;
                      return ChatMessageBubble(message: state.messages[msgIndex]);
                    }
                  },
                );
              },
            ),

            // Nút cuộn xuống dưới cùng khi có tin nhắn mới
            if (!_isNearBottom)
              Positioned(
                right: 16,
                bottom: bottomSafe + 145.0,
                child: GestureDetector(
                  onTap: () {
                    _scrollToBottom();
                    setState(() => _unreadCount = 0);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700, size: 26),
                        if (_unreadCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF2A6D),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _unreadCount > 9 ? '9+' : '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
