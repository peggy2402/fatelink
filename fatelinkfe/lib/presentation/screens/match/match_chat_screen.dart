import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/utils/anonymous_avatar_helper.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/match_user.dart';
import '../../../presentation/widgets/chat_input_bar.dart';
import '../../../presentation/widgets/typing_indicator.dart';
import '../../../services/api_service.dart';

// Components tách rời sạch sẽ
import '../../widgets/cosmic_report_modal.dart';
import '../profile/user_detail_screen.dart';
import 'widgets/match_ai_suggestion_sheet.dart';
import 'widgets/match_options_bottom_sheet.dart';

/// Màn hình trò chuyện giữa 2 người dùng đã ghép đôi (MatchChatScreen):
/// - Kết nối WebSocket Real-time 1-1 qua Socket.IO: gửi & nhận tin nhắn thực tế tức thì
/// - Hỗ trợ tải lịch sử chat (Direct History), trạng thái đang gõ (Typing) và trạng thái Online
/// - Giao diện Cosmic Ethereal sang trọng, sâu thẳm với ánh sáng tinh vân lộng lẫy
/// - Bố cục chuẩn mực: Header tôn vinh khoảnh khắc định mệnh se duyên
/// - Bong bóng tin nhắn Glassmorphism & Gradient Signature FateLink ấm áp
/// - Hàng chip gợi ý phá băng (Icebreaker) thông minh từ Faye AI
class MatchChatScreen extends StatefulWidget {
  final String partnerName;
  final String partnerId;
  final String? partnerAvatar;
  final bool canViewIdentity;
  final String? frequencyHertz;
  final String? moodIcon;
  final MatchUser? partnerUser;

  const MatchChatScreen({
    super.key,
    required this.partnerName,
    required this.partnerId,
    this.partnerAvatar,
    this.canViewIdentity = false,
    this.frequencyHertz,
    this.moodIcon,
    this.partnerUser,
  });

  @override
  State<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends State<MatchChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _secureStorage = SecureStorageHelper.storage;

  IO.Socket? _socket;
  Timer? _typingDebounce;
  bool _isPartnerTyping = false;
  bool _isPartnerOnline = false;
  bool _isLoadingHistory = true;
  final List<ChatMessage> _messages = [];
  bool _isNearBottom = true;
  int _unreadCount = 0;

  // Gợi ý mở lời phá băng (Icebreakers) dễ thương
  final List<String> _icebreakers = [
    'Hôm nay của bạn thế nào? ✨',
    'Bạn thích nghe thể loại nhạc gì? 🎧',
    'Gu trà sữa hay cà phê nè? ☕',
    'Tần số rung cảm hôm nay ra sao? 💫',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _chatController.addListener(_onTextChanged);

    // Kết nối WebSocket Socket.IO và tải lịch sử tin nhắn thực tế
    _initSocketAndLoadHistory();
  }

  Future<void> _initSocketAndLoadHistory() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty) {
        setState(() => _isLoadingHistory = false);
        return;
      }

      // Khởi tạo Socket.IO kết nối tới NestJS backend
      _socket = IO.io(
        AppConstants.serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('✅ [MatchChatSocket] Đã kết nối socket thành công');
        // 1. Tải lịch sử tin nhắn trực tiếp giữa 2 người từ MongoDB
        _socket!.emit('loadDirectHistory', {
          'partnerId': widget.partnerId,
          'limit': 50,
        });

        // 2. Kiểm tra trạng thái trực tuyến của đối phương
        _socket!.emit('checkUserStatus', {
          'targetUserId': widget.partnerId,
        });
      });

      // Lắng nghe kết quả lịch sử tin nhắn từ server
      _socket!.on('directHistoryResult', (data) {
        if (!mounted) return;
        if (data is Map && data['partnerId'] == widget.partnerId) {
          final rawMessages = data['messages'] as List? ?? [];
          final List<ChatMessage> loaded = [];

          for (final item in rawMessages) {
            if (item is Map) {
              loaded.add(
                ChatMessage(
                  text: item['text'] ?? '',
                  isSentByMe: item['isSentByMe'] == true,
                  timestamp: DateTime.tryParse(item['timestamp']?.toString() ?? '')
                          ?.toLocal() ??
                      DateTime.now(),
                ),
              );
            }
          }

          setState(() {
            _messages.clear();
            if (loaded.isNotEmpty) {
              // Sắp xếp tin nhắn mới nhất lên đầu danh sách (reverse: true)
              _messages.addAll(loaded.reversed);
            } else {
              // Nếu chưa có tin nhắn nào trước đây, hiển thị câu chào mở đầu
              _messages.add(
                ChatMessage(
                  text: 'Xin chào! Rất vui vì định mệnh đã kết nối chúng ta hôm nay ✨',
                  isSentByMe: false,
                  timestamp: DateTime.now(),
                ),
              );
            }
            _isLoadingHistory = false;
          });
        }
      });

      // Lắng nghe tin nhắn realtime từ đối phương gửi tới
      _socket!.on('receiveDirectMessage', (data) {
        if (!mounted) return;
        if (data is Map && data['senderId'] == widget.partnerId) {
          HapticFeedback.lightImpact();
          setState(() {
            _isPartnerTyping = false;
            _messages.insert(
              0,
              ChatMessage(
                text: data['text'] ?? '',
                isSentByMe: false,
                timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '')
                        ?.toLocal() ??
                    DateTime.now(),
              ),
            );
          });
          _scrollToBottom();
        }
      });

      // Lắng nghe trạng thái đang gõ từ đối phương
      _socket!.on('receiveTyping', (data) {
        if (!mounted) return;
        if (data is Map && data['senderId'] == widget.partnerId) {
          setState(() {
            _isPartnerTyping = data['isTyping'] == true;
          });
          if (_isPartnerTyping) {
            _scrollToBottom();
          }
        }
      });

      // Lắng nghe kết quả kiểm tra trạng thái online
      _socket!.on('userStatusResult', (data) {
        if (!mounted) return;
        if (data is Map && data['userId'] == widget.partnerId) {
          setState(() {
            _isPartnerOnline = data['isOnline'] == true;
          });
        }
      });

      // Lắng nghe sự kiện đối phương vừa online hoặc offline
      _socket!.on('userStatusChanged', (data) {
        if (!mounted) return;
        if (data is Map && data['userId'] == widget.partnerId) {
          setState(() {
            _isPartnerOnline = data['isOnline'] == true;
          });
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ [MatchChatSocket] Socket bị ngắt kết nối');
      });
    } catch (e) {
      debugPrint('⚠️ [MatchChatSocket] Lỗi khởi tạo socket: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _onTextChanged() {
    if (_socket == null || !_socket!.connected) return;

    // Phát sự kiện đang gõ cho đối phương
    _socket!.emit('typing', {
      'partnerId': widget.partnerId,
      'isTyping': true,
    });

    // Sau 1.5s nếu người dùng dừng gõ thì phát dừng gõ
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('typing', {
          'partnerId': widget.partnerId,
          'isTyping': false,
        });
      }
    });
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
    _typingDebounce?.cancel();
    _scrollController.removeListener(_scrollListener);
    _chatController.removeListener(_onTextChanged);

    // Báo dừng gõ và giải phóng socket
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {
        'partnerId': widget.partnerId,
        'isTyping': false,
      });
      _socket!.dispose();
    }

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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text(
              'Chặn người dùng?',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn chặn ${widget.partnerName}? Người này sẽ bị xóa khỏi danh sách bạn bè và không thể tìm thấy, gửi sóng hay trò chuyện với bạn nữa.',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: Color(0xFF94A3B8),
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
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      final url = '${AppConstants.baseUrl}/${AppConstants.userBlock(widget.partnerId)}';
      await ApiService.post(url, context, token: token, showLoading: true);

      if (!mounted) return;
      ToastUtil.showSuccess(context, 'Đã chặn ${widget.partnerName} thành công');
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
    HapticFeedback.lightImpact();
    MatchAiSuggestionSheet.show(
      context,
      partnerName: widget.partnerName,
      onSelectSuggestion: (text) {
        _chatController.text = text;
      },
    );
  }

  void _navigateToProfile() {
    HapticFeedback.lightImpact();
    // Đã sửa triệt để: Sử dụng đúng cấu trúc MatchUser (name, emotion, compatibilityScore)
    final user = widget.partnerUser ??
        MatchUser(
          id: widget.partnerId,
          name: widget.partnerName,
          emotion: 'Kết nối định mệnh',
          compatibilityScore: 95,
          avatar: widget.partnerAvatar,
          isLiked: true,
          isMutualFollow: true,
          moodIcon: widget.moodIcon ?? '✨',
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    final trimmedText = text.trim();

    // 1. Thêm tin nhắn của mình vào UI tức thời
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: trimmedText,
          isSentByMe: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _chatController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 2. Gửi tin nhắn thực tế qua WebSocket tới backend NestJS
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendDirectMessage', {
        'partnerId': widget.partnerId,
        'text': trimmedText,
      });

      // Báo dừng gõ
      _socket!.emit('typing', {
        'partnerId': widget.partnerId,
        'isTyping': false,
      });
    } else {
      debugPrint('⚠️ [MatchChatSocket] Socket chưa kết nối, đang thử kết nối lại...');
      _socket?.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auraGradient = AnonymousAvatarHelper.getCosmicAuraGradient(widget.partnerId);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      extendBodyBehindAppBar: true,
      appBar: _buildCosmicAppBar(auraGradient),
      body: Stack(
        children: [
          // 1. Nền Gradient Vũ Trụ đa chiều sâu lắng (Cosmic Deep Space)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Slate Cosmic
                  Color(0xFF090D18), // Deep Space Dark
                  Color(0xFF110E24), // Twilight Violet
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Quầng sáng tinh vân lung linh (Nebula Glow Ambient)
          Positioned(
            top: 40,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Nội dung cuộc trò chuyện
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Khung hiển thị danh sách tin nhắn
                Expanded(
                  child: _isLoadingHistory
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              // +1 cho Header se duyên ở đỉnh danh sách
                              itemCount: _messages.length + (_isPartnerTyping ? 1 : 0) + 1,
                              itemBuilder: (context, index) {
                                // Nếu đối phương đang gõ
                                if (_isPartnerTyping) {
                                  if (index == 0) return _buildTypingIndicator(auraGradient);
                                  if (index == _messages.length + 1) {
                                    return _buildMatchCelebrationHeader(auraGradient);
                                  }
                                  return _buildMessageBubble(_messages[index - 1], auraGradient);
                                }

                                // Không có typing
                                if (index == _messages.length) {
                                  return _buildMatchCelebrationHeader(auraGradient);
                                }
                                return _buildMessageBubble(_messages[index], auraGradient);
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
                                      color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),

                // 4. Hàng chip câu hỏi mở lời phá băng (Icebreakers) khi mới bắt đầu
                if (_messages.length <= 3) _buildIcebreakerChips(),

                // 5. Thanh ChatInputBar chuẩn tối mượt mà, kính mờ trải dài
                ChatInputBar(
                  controller: _chatController,
                  showQuickChips: false,
                  isDark: true,
                  hintText: 'Nhắn tin cho ${widget.partnerName}...',
                  onSubmitted: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar kính mờ Cosmic Glass sang trọng
  PreferredSizeWidget _buildCosmicAppBar(LinearGradient auraGradient) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    // Nút Back tròn thanh lịch
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Avatar + Tên + Trạng thái (Bấm vào để xem Profile)
                    Expanded(
                      child: GestureDetector(
                        onTap: _navigateToProfile,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            // Avatar tròn với viền hào quang
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: auraGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: auraGradient.colors.first.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: widget.canViewIdentity &&
                                            widget.partnerAvatar != null &&
                                            widget.partnerAvatar!.isNotEmpty
                                        ? Image.network(
                                            widget.partnerAvatar!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, st) =>
                                                _buildDefaultAvatar(),
                                          )
                                        : Image.asset(
                                            AnonymousAvatarHelper.getAnonymousAvatarAsset(widget.partnerId),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                // Chấm xanh ngọc Online
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: _isPartnerOnline
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF64748B),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0F172A),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),

                            // Tên và thông tin tần số / linh vật
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.partnerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      if (widget.canViewIdentity)
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xFF3B82F6),
                                          size: 15,
                                        )
                                      else
                                        const Icon(
                                          Icons.lock_rounded,
                                          color: Color(0xFFEC4899),
                                          size: 13,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.sensors_rounded,
                                        color: _isPartnerOnline
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF64748B),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          _isPartnerOnline
                                              ? '${widget.frequencyHertz ?? "528 Hz"} • Đang phát sóng'
                                              : '${widget.frequencyHertz ?? "528 Hz"} • Ngoại tuyến',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            color: _isPartnerOnline
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF64748B),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Nút AI gợi ý mở lời thông minh
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Faye AI gợi ý câu mở lời',
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF00E5FF),
                          size: 19,
                        ),
                        onPressed: _showAiSuggestionModal,
                      ),
                    ),

                    // Nút Tuỳ chọn 3 chấm
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                      onPressed: _showOptionsModal,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Thẻ chúc mừng se duyên định mệnh ở đầu danh sách tin nhắn
  Widget _buildMatchCelebrationHeader(LinearGradient auraGradient) {
    final personaName = AnonymousAvatarHelper.getAnonymousPersonaName(widget.partnerId);

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Avatar lớn với vòng hào quang phát sáng
          Center(
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: auraGradient,
                boxShadow: [
                  BoxShadow(
                    color: auraGradient.colors.first.withValues(alpha: 0.4),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.canViewIdentity &&
                        widget.partnerAvatar != null &&
                        widget.partnerAvatar!.isNotEmpty
                    ? Image.network(
                        widget.partnerAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => _buildDefaultAvatar(),
                      )
                    : Image.asset(
                        AnonymousAvatarHelper.getAnonymousAvatarAsset(widget.partnerId),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tên đối phương
          Text(
            widget.partnerName,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Chip Linh vật & Tần số
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.15),
                  const Color(0xFFEC4899).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 5),
                Text(
                  'Linh vật: $personaName • ${widget.frequencyHertz ?? "528 Hz"}',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF818CF8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Lời chúc se duyên
          const Text(
            'Hai bạn đã tìm thấy nhau giữa triệu tần số vũ trụ.\nHãy cùng mở đầu một cuộc trò chuyện chân thành nhé! ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Huy hiệu bảo mật
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF64748B),
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  'Cuộc trò chuyện được mã hóa tâm hồn',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hàng chip câu hỏi gợi ý mở lời (Icebreakers)
  Widget _buildIcebreakerChips() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _icebreakers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _icebreakers[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _handleSendMessage(prompt);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFFE2E8F0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Bong bóng tin nhắn chuẩn mực UI/UX
  Widget _buildMessageBubble(ChatMessage msg, LinearGradient auraGradient) {
    final isMe = msg.isSentByMe;
    final timeString =
        "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar nhỏ đối phương bên trái
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: auraGradient,
              ),
              padding: const EdgeInsets.all(1.5),
              child: ClipOval(
                child: widget.canViewIdentity &&
                        widget.partnerAvatar != null &&
                        widget.partnerAvatar!.isNotEmpty
                    ? Image.network(
                        widget.partnerAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => _buildDefaultAvatar(),
                      )
                    : Image.asset(
                        AnonymousAvatarHelper.getAnonymousAvatarAsset(widget.partnerId),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ],

          // Khung bong bóng tin nhắn
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 15),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            const Color(0xFF1E293B).withValues(alpha: 0.92),
                            const Color(0xFF161F30).withValues(alpha: 0.92),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: isMe
                          ? const Color(0xFF6366F1).withValues(alpha: 0.32)
                          : Colors.black.withValues(alpha: 0.25),
                      blurRadius: isMe ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(height: 3),

              // Thời gian gửi + Icon đã xem
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeString,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        color: Color(0xFF00E5FF),
                        size: 13,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Typing indicator tinh tế
  Widget _buildTypingIndicator(LinearGradient auraGradient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: auraGradient,
            ),
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: Image.asset(
                AnonymousAvatarHelper.getAnonymousAvatarAsset(widget.partnerId),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const TypingIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF312E81),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
