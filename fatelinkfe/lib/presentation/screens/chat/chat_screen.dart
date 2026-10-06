import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/app_socket_service.dart';
import '../../../services/badge_service.dart';
import '../../../logic/blocs/chat/chat_bloc.dart';
import '../../../logic/blocs/chat/chat_event.dart';
import '../../../logic/blocs/chat/chat_state.dart';
import '../../../logic/blocs/home/home_bloc.dart';
import '../../../logic/blocs/home/home_event.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/chat_conversation_tile.dart';
import 'widgets/chat_conversation_options_modal.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_online_stories.dart';
import 'widgets/chat_room_app_bar.dart';
import 'widgets/chat_typing_indicator_bubble.dart';
import 'widgets/chat_filter_chips.dart';
import 'widgets/chat_empty_state.dart';
import 'widgets/chat_pending_waves_modal.dart';
import '../match/cosmic_broadcast_screen.dart';
import '../match/match_chat_screen.dart';
import '../home/widgets/radar_scanner_modal.dart';
import '../home/widgets/notifications_modal.dart';
import '../../widgets/cosmic_pulse_received_modal.dart';
import '../../../services/api_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/secure_storage_helper.dart';

/// Dữ liệu tổng hợp một cuộc hội thoại trực tiếp lấy từ API
class DirectConversationMeta {
  final String partnerId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isSentByMe;
  final int unreadCount;

  DirectConversationMeta({
    required this.partnerId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isSentByMe = false,
    this.unreadCount = 0,
  });
}

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
  String? _currentUserFrequency;

  // Dữ liệu tin nhắn & thông báo thực tế nạp từ Backend API
  Map<String, DirectConversationMeta> _recentConversations = {};
  NotificationItem? _latestSystemNotification;
  int _systemUnreadCount = 0;
  StreamSubscription? _socketSub;

  // Cấu hình cá nhân: Ghim hội thoại & Tắt thông báo
  Set<String> _pinnedUserIds = {};
  Map<String, DateTime?> _mutedUntilMap = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _loadUserFrequency();
    _loadChatPreferences();
    _fetchDirectConversationsAndNotifications();
    context.read<ChatBloc>().add(ChatInitializeEvent(context));

    // Lắng nghe tin nhắn mới thời gian thực từ AppSocketService để cập nhật danh sách
    _socketSub = AppSocketService.instance.messageStream.listen((event) {
      if (!mounted) return;
      final senderId = event['senderId']?.toString() ?? '';
      final text = event['text']?.toString() ?? '';
      final msgType = event['messageType']?.toString() ?? 'text';
      final displayContent = msgType == 'voice' ? '🎤 Tin nhắn thoại' : text;
      if (senderId.isNotEmpty) {
        setState(() {
          _recentConversations[senderId] = DirectConversationMeta(
            partnerId: senderId,
            lastMessage: displayContent,
            lastMessageTime: DateTime.now(),
            isSentByMe: false,
            unreadCount: (_recentConversations[senderId]?.unreadCount ?? 0) + 1,
          );
        });
        _recalcTotalUnread();
      }
    });
  }

  /// Nạp danh sách ghim và tắt thông báo từ SharedPreferences
  Future<void> _loadChatPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinned = prefs.getStringList('chat_pinned_ids') ?? [];
      final mutedKeys = prefs.getKeys().where((k) => k.startsWith('chat_muted_until_')).toList();
      final Map<String, DateTime?> muted = {};
      final now = DateTime.now();
      for (final key in mutedKeys) {
        final uId = key.replaceFirst('chat_muted_until_', '');
        final val = prefs.getString(key);
        if (val == 'forever') {
          muted[uId] = null;
        } else if (val != null) {
          final exp = DateTime.tryParse(val);
          if (exp != null && exp.isAfter(now)) {
            muted[uId] = exp;
          } else {
            await prefs.remove(key); // Đã hết hạn tắt thông báo
          }
        }
      }
      if (mounted) {
        setState(() {
          _pinnedUserIds = pinned.toSet();
          _mutedUntilMap = muted;
        });
      }
    } catch (_) {}
  }

  bool _isUserMuted(String userId) {
    if (!_mutedUntilMap.containsKey(userId)) return false;
    final until = _mutedUntilMap[userId];
    if (until == null) return true; // Vĩnh viễn
    return DateTime.now().isBefore(until);
  }

  Future<void> _togglePinUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_pinnedUserIds.contains(userId)) {
        _pinnedUserIds.remove(userId);
      } else {
        _pinnedUserIds.add(userId);
      }
    });
    await prefs.setStringList('chat_pinned_ids', _pinnedUserIds.toList());
    HapticFeedback.lightImpact();
  }

  Future<void> _muteUser(String userId, Duration? duration) async {
    final prefs = await SharedPreferences.getInstance();
    final until = duration != null ? DateTime.now().add(duration) : null;
    setState(() {
      _mutedUntilMap[userId] = until;
    });
    final key = 'chat_muted_until_$userId';
    if (until == null) {
      await prefs.setString(key, 'forever');
    } else {
      await prefs.setString(key, until.toIso8601String());
    }
    if (mounted) {
      final label = duration == null
          ? 'cho đến khi bật lại'
          : (duration.inHours >= 24
              ? 'trong 1 ngày'
              : (duration.inHours >= 4
                  ? 'trong 4 giờ'
                  : 'trong 1 giờ'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tắt thông báo $label'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _unmuteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mutedUntilMap.remove(userId);
    });
    await prefs.remove('chat_muted_until_$userId');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bật lại thông báo cuộc trò chuyện'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _deleteConversation(String userId) async {
    setState(() {
      _recentConversations.remove(userId);
    });
    _recalcTotalUnread();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa cuộc trò chuyện khỏi danh sách'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _blockUser(String userId) async {
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token == null || !mounted) return;
      await ApiService.post(
        '${AppConstants.baseUrl}/users/$userId/block',
        context,
        token: token,
        showLoading: false,
      );
      if (!mounted) return;
      setState(() {
        _recentConversations.remove(userId);
      });
      _recalcTotalUnread();
      context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chặn người dùng thành công'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Lỗi chặn người dùng: $e');
    }
  }

  Future<void> _reportUser(String userId) async {
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token == null || !mounted) return;
      await ApiService.post(
        '${AppConstants.baseUrl}/users/$userId/report',
        context,
        body: {'reason': 'Quấy rối / Spam hoặc nội dung không phù hợp'},
        token: token,
        showLoading: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi báo cáo vi phạm. Đội ngũ FateLink sẽ kiểm tra trong 24h.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Lỗi báo cáo người dùng: $e');
    }
  }

  Future<void> _unmatchUser(String userId) async {
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token == null || !mounted) return;
      await ApiService.delete(
        '${AppConstants.baseUrl}/matches/$userId/unmatch',
        context,
        token: token,
        showLoading: false,
      );
      if (!mounted) return;
      setState(() {
        _recentConversations.remove(userId);
      });
      _recalcTotalUnread();
      context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy ghép đôi thành công'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Lỗi hủy ghép đôi: $e');
    }
  }

  void _recalcTotalUnread() {
    final total = _recentConversations.values.fold<int>(
      0,
      (sum, item) => sum + item.unreadCount,
    );
    AppSocketService().totalUnreadCount.value = total;
    BadgeService.updateBadgeCount(total);
  }

  /// Nạp tin nhắn gần nhất của bạn bè và thông báo hệ thống THẬT từ API
  Future<void> _fetchDirectConversationsAndNotifications() async {
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token == null || token.isEmpty || !mounted) return;

      // 1. Lấy danh sách hội thoại trực tiếp gần nhất từ API
      final convUrl = '${AppConstants.baseUrl}/messages/conversations';
      final convRes = await ApiService.get(convUrl, context, token: token, showLoading: false);
      if (convRes is List && mounted) {
        final Map<String, DirectConversationMeta> map = {};
        for (final item in convRes) {
          if (item is Map) {
            final pId = item['partnerId']?.toString() ?? '';
            final text = item['lastMessage']?.toString() ?? '';
            final timeStr = item['lastMessageTime']?.toString() ?? '';
            final parsedTime = DateTime.tryParse(timeStr)?.toLocal() ?? DateTime.now();
            final isSentByMe = item['isSentByMe'] == true;
            final unread = int.tryParse(item['unreadCount']?.toString() ?? '0') ?? 0;
            if (pId.isNotEmpty) {
              map[pId] = DirectConversationMeta(
                partnerId: pId,
                lastMessage: text,
                lastMessageTime: parsedTime,
                isSentByMe: isSentByMe,
                unreadCount: unread,
              );
            }
          }
        }
        setState(() {
          _recentConversations = map;
        });
        _recalcTotalUnread();
      }

      // 2. Lấy thông báo hệ thống FateLink từ API
      if (!mounted) return;
      final notifUrl = '${AppConstants.baseUrl}/${AppConstants.notifications}';
      final notifRes = await ApiService.get(notifUrl, context, token: token, showLoading: false);
      List<dynamic>? rawList;
      if (notifRes is List) {
        rawList = notifRes;
      } else if (notifRes is Map<String, dynamic> && notifRes['data'] is List) {
        rawList = notifRes['data'] as List;
      }

      if (rawList != null && rawList.isNotEmpty && mounted) {
        final notifs = rawList
            .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
            .toList();
        final unreadCount = notifs.where((n) => !n.isRead).length;
        setState(() {
          _latestSystemNotification = notifs.first;
          _systemUnreadCount = unreadCount;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [ChatScreen] Lỗi nạp tin nhắn/thông báo thực tế: $e');
    }
  }

  String _formatConversationTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays == 0 && now.day == timestamp.day) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != timestamp.day)) {
      return 'Hôm qua';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _loadUserFrequency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedHertz = prefs.getString('user_frequency_hertz');
      if (cachedHertz != null && cachedHertz.isNotEmpty && mounted) {
        setState(() {
          _currentUserFrequency = cachedHertz;
        });
      }
    } catch (_) {}
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
    _socketSub?.cancel();
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
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
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

              // 2. Phát sóng tần số cảm xúc thực tế
              _buildActionItem(
                icon: Icons.podcasts_rounded,
                color: const Color(0xFFEC4899),
                title:
                    'Phát sóng tần số ${_currentUserFrequency ?? '528 Hz'}',
                subtitle: 'Tìm người cùng gu tần số cảm xúc trong 120 giây',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CosmicBroadcastScreen(),
                    ),
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
                    onConnectMatch: () =>
                        Navigator.of(context).pushNamed('/matches'),
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
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
          if (_isSearchOpen) SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(
            child: Builder(
              builder: (ctx) {
                final allUsers = ctx.watch<HomeBloc>().state.matchedUsers;
                // QUY TẮC BẢO MẬT SOULMATE:
                // CHỈ những người ĐÃ CÙNG THẢ TIM NHAU (Mutual Follow) mới được hiển thị trên Stories bạn bè!
                // Người chưa thả tim hoặc người chỉ mới gửi sóng sẽ được đưa vào "Tín hiệu sóng chờ kết nối".
                final mutualUsers = allUsers
                    .where((u) => u.isMutualFollow)
                    .toList();
                return ChatOnlineStories(
                  onFayeTap: _switchToRoomView,
                  onlineUsers: mutualUsers,
                  onUserTap: (user) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MatchChatScreen(
                          partnerName: user.name,
                          partnerId: user.id,
                        ),
                      ),
                    );
                  },
                  onDiscoverTap: _showNewChatActionModal,
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Builder(
              builder: (ctx) {
                final allUsers = ctx.watch<HomeBloc>().state.matchedUsers;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: ChatFilterChips(
                    allUsers: allUsers,
                    selectedFilter: _selectedFilter,
                    onFilterSelected: (key) => setState(() => _selectedFilter = key),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
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
              color: _isSearchOpen
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF475569),
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF6366F1),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    final chatState = context.watch<ChatBloc>().state;
    final allUsers = context.watch<HomeBloc>().state.matchedUsers;

    // QUY TẮC BẢO MẬT & HÒA ÂM TẦM HỒN:
    // 1. Bạn bè đã kết đôi (Mutual Matches - cả 2 đã cùng thả tim nhau)
    final mutualMatches = allUsers.where((u) => u.isMutualFollow).toList();
    // 2. Những người phát sóng rung cảm đến bạn hoặc bạn chưa thả tim đáp lại
    final pendingWaves = allUsers.where((u) => !u.isMutualFollow).toList();

    // 1. Phân tích tin nhắn cuối cùng của Faye AI
    final hasAiMessages = chatState.messages.isNotEmpty;
    final lastAiMsg = hasAiMessages ? chatState.messages.last : null;
    final String lastAiText = lastAiMsg != null
        ? lastAiMsg.text
        : 'Chào bạn, hôm nay của bạn thế nào?';
    final String lastAiTime = lastAiMsg != null
        ? '${lastAiMsg.timestamp.hour.toString().padLeft(2, '0')}:${lastAiMsg.timestamp.minute.toString().padLeft(2, '0')}'
        : '10:36';

    // 2. Gom danh sách các item hiển thị
    final List<Widget> conversationTiles = [];

    // Item 1: Faye AI
    final bool matchFaye =
        _searchQuery.isEmpty ||
        'faye ai'.contains(_searchQuery.toLowerCase()) ||
        lastAiText.toLowerCase().contains(_searchQuery.toLowerCase());
    final bool showFaye =
        matchFaye &&
        (_selectedFilter == 'all' ||
            _selectedFilter == 'ai' ||
            _selectedFilter == 'unread');

    if (showFaye) {
      conversationTiles.add(
        ChatConversationTile(
          name: 'Faye AI',
          imageUrl: 'assets/images/avt_faye_ai.png',
          lastMessage: lastAiText,
          time: lastAiTime,
          unreadCount: hasAiMessages ? 0 : 1,
          isBot: true,
          onTap: _switchToRoomView,
        ),
      );
    }

    // Item 2: Tin nhắn hệ thống FateLink nạp thật từ API Notifications
    final bool matchSystem =
        _searchQuery.isEmpty ||
        'hệ thống fatelink'.contains(_searchQuery.toLowerCase()) ||
        'thông báo'.contains(_searchQuery.toLowerCase());
    final bool showSystem = matchSystem && (_selectedFilter == 'all');

    if (showSystem) {
      final notif = _latestSystemNotification;
      final systemLastMsg = notif != null
          ? (notif.message.isNotEmpty ? notif.message : notif.title)
          : 'Chào mừng bạn đến với FateLink! Khám phá tần số tâm hồn ngay ✨';
      final systemTime = notif != null
          ? _formatConversationTime(notif.createdAt)
          : 'Hôm nay';

      conversationTiles.add(
        ChatConversationTile(
          name: 'Hệ thống FateLink',
          systemIcon: Icons.all_inclusive_rounded,
          lastMessage: systemLastMsg,
          time: systemTime,
          unreadCount: _systemUnreadCount,
          isSystem: true,
          onTap: () async {
            await NotificationsModal.show(context);
            if (mounted) {
              _fetchDirectConversationsAndNotifications();
            }
          },
        ),
      );
    }

    // Item 3: TÍN HIỆU SÓNG CHỜ KẾT NỐI (Tin nhắn chờ)
    // Người chưa thả tim nhau TUYỆT ĐỐI KHÔNG xuất hiện lẻ tẻ lẫn lộn vào danh sách trò chuyện chính,
    // mà được gom lại thành mục chờ đặc biệt để người dùng hòa âm hoặc mở khóa!
    final bool showPendingWaves =
        pendingWaves.isNotEmpty &&
        (_selectedFilter == 'all' || _selectedFilter == 'pending') &&
        (_searchQuery.isEmpty ||
            'tín hiệu sóng chờ kết nối tin nhắn'.contains(
              _searchQuery.toLowerCase(),
            ));

    if (showPendingWaves) {
      conversationTiles.add(
        ChatConversationTile(
          name: 'Tín hiệu sóng chờ kết nối',
          systemIcon: Icons.sensors_rounded,
          lastMessage: pendingWaves.length == 1
              ? '${pendingWaves.first.anonymousName} vừa phát sóng rung cảm • Chạm để hòa âm & kết nối'
              : 'Có ${pendingWaves.length} người đang phát sóng rung cảm đến bạn • Chạm để hòa âm & kết nối',
          time: 'Mới nhận',
          unreadCount: pendingWaves.length,
          isWaveRequest: true,
          onTap: () {
            if (pendingWaves.length == 1) {
              CosmicPulseReceivedModal.show(
                context,
                sender: pendingWaves.first,
              );
            } else {
              ChatPendingWavesModal.show(context, pendingWaves);
            }
          },
        ),
      );
    }

    // Item 4+: CÁC BẠN BÈ ĐÃ KẾT ĐÔI CHÍNH THỨC (Mutual Matches)
    // CHỈ hiển thị những người CẢ HAI ĐÃ CÙNG THẢ TIM NHAU!
    // Lấy tin nhắn thực tế từ cơ sở dữ liệu qua API /messages/conversations
    if (_selectedFilter == 'all' || _selectedFilter == 'matches') {
      // Sắp xếp: Ưu tiên cuộc hội thoại ĐƯỢC GHIM lên đầu, sau đó sắp xếp theo thời gian tin nhắn mới nhất
      final sortedMatches = List.of(mutualMatches);
      sortedMatches.sort((a, b) {
        final aPinned = _pinnedUserIds.contains(a.id);
        final bPinned = _pinnedUserIds.contains(b.id);
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;

        final aTime = _recentConversations[a.id]?.lastMessageTime;
        final bTime = _recentConversations[b.id]?.lastMessageTime;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime);
        }
        if (aTime != null) return -1;
        if (bTime != null) return 1;
        return 0;
      });

      for (final user in sortedMatches) {
        final String displayName = user.name;
        final String avatarUrl = user.avatar ?? '';

        final directMeta = _recentConversations[user.id];
        final String effectiveLastMessage = directMeta != null && directMeta.lastMessage.isNotEmpty
            ? (directMeta.isSentByMe ? 'Bạn: ${directMeta.lastMessage}' : directMeta.lastMessage)
            : 'Đã kết đôi • Mở khóa trò chuyện vĩnh viễn 💕';
        final String effectiveTime = directMeta != null
            ? _formatConversationTime(directMeta.lastMessageTime)
            : 'Vừa xong';
        final int effectiveUnread = directMeta?.unreadCount ?? 0;

        final bool matchUser =
            _searchQuery.isEmpty ||
            displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.emotion.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            effectiveLastMessage.toLowerCase().contains(_searchQuery.toLowerCase());

        if (matchUser) {
          final progress = (user.compatibilityScore / 100.0).clamp(0.0, 1.0);
          final calculatedAge = user.age ?? (18 + (user.id.hashCode.abs() % 7));
          final calculatedGender = user.gender ?? (user.id.hashCode % 2 == 0 ? 'female' : 'male');
          final isPinned = _pinnedUserIds.contains(user.id);
          final isMuted = _isUserMuted(user.id);

          conversationTiles.add(
            ChatConversationTile(
              name: displayName,
              imageUrl: avatarUrl,
              lastMessage: effectiveLastMessage,
              time: effectiveTime,
              unreadCount: effectiveUnread,
              isPinned: isPinned,
              isMuted: isMuted,
              gender: calculatedGender,
              age: calculatedAge,
              meyuFeelProgress: progress,
              onTap: () async {
                // Đánh dấu đã đọc cuộc trò chuyện này
                if (_recentConversations.containsKey(user.id)) {
                  setState(() {
                    final old = _recentConversations[user.id]!;
                    _recentConversations[user.id] = DirectConversationMeta(
                      partnerId: old.partnerId,
                      lastMessage: old.lastMessage,
                      lastMessageTime: old.lastMessageTime,
                      isSentByMe: old.isSentByMe,
                      unreadCount: 0,
                    );
                  });
                  _recalcTotalUnread();
                }

                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MatchChatScreen(
                      partnerName: user.name,
                      partnerId: user.id,
                    ),
                  ),
                );
                if (mounted) {
                  _fetchDirectConversationsAndNotifications();
                }
              },
              onLongPress: () {
                ChatConversationOptionsModal.show(
                  context,
                  userId: user.id,
                  userName: displayName,
                  userAvatar: avatarUrl,
                  isPinned: isPinned,
                  isMuted: isMuted,
                  onTogglePin: () => _togglePinUser(user.id),
                  onMute: (duration) => _muteUser(user.id, duration),
                  onUnmute: () => _unmuteUser(user.id),
                  onDeleteConversation: () => _deleteConversation(user.id),
                  onBlockUser: () => _blockUser(user.id),
                  onReportUser: () => _reportUser(user.id),
                  onUnmatchUser: () => _unmatchUser(user.id),
                );
              },
            ),
          );
        }
      }
    }

    // Trạng thái trống khi tìm kiếm hoặc lọc không có kết quả
    if (conversationTiles.isEmpty) {
      return const SliverToBoxAdapter(
        child: ChatEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => conversationTiles[index],
        childCount: conversationTiles.length,
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
      appBar: ChatRoomAppBar(onBack: _switchToListView),
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
              setState(
                () => _unreadCount +=
                    (state.messages.length - _previousMessageCount),
              );
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
                if (state.status == ChatStatus.loading &&
                    state.messages.isEmpty) {
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
                      return ChatMessageBubble(
                        message: state.messages[msgIndex],
                      );
                    } else {
                      final msgIndex = state.messages.length - 1 - index;
                      return ChatMessageBubble(
                        message: state.messages[msgIndex],
                      );
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
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade700,
                          size: 26,
                        ),
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
