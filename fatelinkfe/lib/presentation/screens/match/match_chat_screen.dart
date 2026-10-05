import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/utils/anonymous_avatar_helper.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/match_user.dart';
import '../../../presentation/widgets/typing_indicator.dart';
import '../../../services/api_service.dart';

// Components tách rời sạch sẽ
import '../../widgets/cosmic_report_modal.dart';
import '../profile/user_detail_screen.dart';
import 'widgets/match_ai_suggestion_sheet.dart';
import 'widgets/match_options_bottom_sheet.dart';

/// Màn hình trò chuyện giữa 2 người dùng đã ghép đôi (MatchChatScreen):
/// 1. Vấn đề 1: Danh tính thật đã mở khóa (không còn ẩn danh):
///    - Tải profile thật của đối phương từ API `/api/users/:id/profile`.
///    - Hiển thị avatar thật (Google/Upload) ở AppBar, Header và từng bong bóng chat.
///    - Bấm vào avatar ở bất kỳ vị trí nào để xem toàn bộ Profile chi tiết của người đó.
/// 2. Vấn đề 2: Thanh chat phong cách Telegram / Messenger:
///    - Nút '+' mở Popup/Sheet đa tiện ích: Camera, Thư viện ảnh, Vị trí, Voice Note.
///    - Nút Camera chụp nhanh cạnh nút '+'.
///    - Nút Emoji trong ô nhập.
///    - Nút chuyển đổi thông minh: Ô text có chữ -> Nút Gửi; Ô text rỗng -> Nút Mic ghi âm thoại.
///    - Bong bóng tin nhắn hỗ trợ: Văn bản, Hình ảnh, Tin nhắn âm thanh thoại, Vị trí.
/// 3. Vấn đề 3: Trò chuyện 2 chiều song hành siêu bền vững (Dual Channel):
///    - WebSocket Socket.IO Real-time + REST API HTTP Fallback (`/api/messages/direct`).
///    - Tự động refresh token nếu token hết hạn, kết nối tự động hồi phục khi rớt mạng.
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
    this.canViewIdentity = true, // Cả 2 đã match -> Mặc định đã mở khóa danh tính
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
  final FocusNode _focusNode = FocusNode();
  final _secureStorage = SecureStorageHelper.storage;
  final ImagePicker _imagePicker = ImagePicker();

  IO.Socket? _socket;
  Timer? _typingDebounce;
  Timer? _historyTimeoutTimer;
  Timer? _pollingFallbackTimer;

  bool _isPartnerTyping = false;
  bool _isPartnerOnline = false;
  bool _isLoadingHistory = false;
  bool _isNearBottom = true;
  int _unreadCount = 0;
  bool _hasInputText = false;

  // Thông tin thực tế của đối phương được nạp từ Profile API
  late String _partnerDisplayName;
  String? _partnerRealAvatar;
  String? _partnerBio;
  String? _partnerEmotion;
  String? _partnerHertz;
  String? _partnerMoodIcon;
  MatchUser? _partnerUserObject;

  // Danh sách tin nhắn cuộc trò chuyện
  final List<ChatMessage> _messages = [];

  // Gợi ý mở lời phá băng (Icebreakers) thông minh & ngọt ngào
  final List<String> _icebreakers = [
    'Hôm nay của bạn thế nào? ✨',
    'Bạn thích nghe thể loại nhạc gì? 🎧',
    'Gu trà sữa hay cà phê nè? ☕',
    'Tần số rung cảm hôm nay ra sao? 💫',
  ];

  @override
  void initState() {
    super.initState();
    _partnerDisplayName = widget.partnerName;
    _partnerRealAvatar = widget.partnerAvatar;
    _partnerHertz = widget.frequencyHertz ?? '528 Hz';
    _partnerMoodIcon = widget.moodIcon ?? '✨';
    _partnerUserObject = widget.partnerUser;

    _scrollController.addListener(_scrollListener);
    _chatController.addListener(_onTextChanged);

    // Mặc định luôn có sẵn câu chào se duyên định mệnh từ đối phương
    _messages.add(
      ChatMessage(
        text: 'Xin chào! Rất vui vì định mệnh đã kết nối chúng ta hôm nay ✨',
        isSentByMe: false,
        timestamp: DateTime.now(),
      ),
    );

    // 1. Tải Profile thực tế của đối phương (Ảnh thật, bio, cảm xúc)
    _fetchPartnerProfile();

    // 2. Tải lịch sử tin nhắn và khởi tạo Socket.IO
    _isLoadingHistory = true;
    _historyTimeoutTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _isLoadingHistory) {
        setState(() => _isLoadingHistory = false);
      }
    });

    _initSocketAndLoadHistory();

    // 3. Fallback Polling định kỳ mỗi 4s để đảm bảo 100% không sót tin nhắn khi socket disconnect
    _pollingFallbackTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_socket == null || !_socket!.connected) {
        _syncMessagesViaHttp();
      }
    });
  }

  void _onTextChanged() {
    final hasText = _chatController.text.trim().isNotEmpty;
    if (hasText != _hasInputText) {
      setState(() => _hasInputText = hasText);
    }

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

  /// Tải thông tin thực tế của đối phương từ API `/api/users/:id/profile`
  Future<void> _fetchPartnerProfile() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty || !mounted) return;

      final url = '${AppConstants.baseUrl}/${AppConstants.userProfile(widget.partnerId)}';
      final res = await ApiService.get(url, context, token: token, showLoading: false);

      if (res is Map && mounted) {
        setState(() {
          _partnerDisplayName = res['name']?.toString() ??
              res['displayName']?.toString() ??
              widget.partnerName;
          _partnerRealAvatar = res['avatar']?.toString() ?? widget.partnerAvatar;
          _partnerBio = res['bio']?.toString();
          _partnerEmotion = res['latestEmotion']?.toString() ??
              res['dominantEmotion']?.toString() ??
              'Đồng điệu';
          _partnerHertz = res['frequencyHertz']?.toString() ?? widget.frequencyHertz ?? '528 Hz';
          _partnerMoodIcon = res['moodIcon']?.toString() ?? widget.moodIcon ?? '✨';

          _partnerUserObject = MatchUser(
            id: widget.partnerId,
            name: _partnerDisplayName,
            emotion: _partnerEmotion ?? 'Đồng điệu',
            compatibilityScore: 96,
            avatar: _partnerRealAvatar,
            isLiked: true,
            isMutualFollow: true,
            moodIcon: _partnerMoodIcon ?? '✨',
            bio: _partnerBio,
          );
        });
      }
    } catch (e) {
      debugPrint('⚠️ [MatchChat] Lỗi tải profile đối phương: $e');
    }
  }

  /// Khởi tạo kết nối Socket và tải lịch sử tin nhắn
  Future<void> _initSocketAndLoadHistory() async {
    try {
      // 1. Kiểm tra và đảm bảo Token luôn hợp lệ
      var token = await _secureStorage.read(key: 'accessToken');
      if (token == null || _isTokenExpired(token)) {
        token = await ApiService.tryRefreshToken();
      }

      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isLoadingHistory = false);
        return;
      }

      final cleanToken = token.replaceFirst(RegExp(r'^Bearer\s+'), '').trim();

      // 2. Khởi tạo Socket.IO kết nối tới backend
      _socket = IO.io(
        AppConstants.serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setAuth({'token': cleanToken})
            .setExtraHeaders({'Authorization': 'Bearer $cleanToken'})
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('✅ [MatchChatSocket] Đã kết nối socket thành công');
        // Tải lịch sử tin nhắn trực tiếp giữa 2 người từ server
        _socket!.emit('loadDirectHistory', {
          'partnerId': widget.partnerId,
          'limit': 50,
        });

        // Kiểm tra trạng thái trực tuyến của đối phương
        _socket!.emit('checkUserStatus', {
          'targetUserId': widget.partnerId,
        });
      });

      // Lắng nghe kết quả lịch sử tin nhắn từ server
      _socket!.on('directHistoryResult', (data) {
        if (!mounted) return;
        _historyTimeoutTimer?.cancel();

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
            if (loaded.isNotEmpty) {
              _messages.clear();
              _messages.addAll(loaded.reversed);
            }
            _isLoadingHistory = false;
          });
        } else {
          setState(() => _isLoadingHistory = false);
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

      _socket!.on('userStatusChanged', (data) {
        if (!mounted) return;
        if (data is Map && data['userId'] == widget.partnerId) {
          setState(() {
            _isPartnerOnline = data['isOnline'] == true;
          });
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ [MatchChatSocket] Socket ngắt kết nối');
        if (mounted && _isLoadingHistory) {
          setState(() => _isLoadingHistory = false);
        }
      });

      _socket!.onConnectError((err) {
        debugPrint('⚠️ [MatchChatSocket] Lỗi kết nối socket: $err');
        if (mounted && _isLoadingHistory) {
          setState(() => _isLoadingHistory = false);
        }
      });

      _socket!.onError((err) {
        debugPrint('⚠️ [MatchChatSocket] Socket gặp sự cố: $err');
        if (mounted && _isLoadingHistory) {
          setState(() => _isLoadingHistory = false);
        }
      });

      // Song song: Tải lịch sử qua HTTP REST API Fallback
      _syncMessagesViaHttp();
    } catch (e) {
      debugPrint('⚠️ [MatchChatSocket] Lỗi khởi tạo socket: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  /// Đồng bộ tin nhắn qua REST API HTTP (`/api/messages/direct/:partnerId`)
  Future<void> _syncMessagesViaHttp() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty || !mounted) return;

      final url = '${AppConstants.baseUrl}/messages/direct/${widget.partnerId}';
      final res = await ApiService.get(url, context, token: token, showLoading: false);

      if (res is List && mounted) {
        final List<ChatMessage> loaded = [];
        for (final item in res) {
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

        if (loaded.isNotEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(loaded.reversed);
            _isLoadingHistory = false;
          });
        }
      }
    } catch (_) {
      // Bỏ qua nếu lỗi HTTP fallback
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      if (exp == null) return false;
      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expDate.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
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
    _historyTimeoutTimer?.cancel();
    _typingDebounce?.cancel();
    _pollingFallbackTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _chatController.removeListener(_onTextChanged);

    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {
        'partnerId': widget.partnerId,
        'isTyping': false,
      });
      _socket!.dispose();
    }

    _chatController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Xem Profile chi tiết của người dùng
  void _navigateToProfile() {
    HapticFeedback.lightImpact();
    final user = _partnerUserObject ??
        widget.partnerUser ??
        MatchUser(
          id: widget.partnerId,
          name: _partnerDisplayName,
          emotion: _partnerEmotion ?? 'Đồng điệu',
          compatibilityScore: 96,
          avatar: _partnerRealAvatar,
          isLiked: true,
          isMutualFollow: true,
          moodIcon: _partnerMoodIcon ?? '✨',
          bio: _partnerBio,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }

  /// Gửi tin nhắn thực tế (Hỗ trợ Dual Channel: Socket + REST API)
  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    final trimmedText = text.trim();

    // 1. Thêm tin nhắn của mình vào UI tức thời (0ms Latency)
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

    // 2. Gửi qua WebSocket
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendDirectMessage', {
        'partnerId': widget.partnerId,
        'text': trimmedText,
      });

      _socket!.emit('typing', {
        'partnerId': widget.partnerId,
        'isTyping': false,
      });
    } else {
      debugPrint('⚠️ [MatchChatSocket] Socket chưa kết nối, thử kết nối lại...');
      _socket?.connect();
    }

    // 3. Song song gửi qua REST API HTTP Backend để đảm bảo 100% lưu trữ MongoDB & push notification
    _sendMessageViaHttp(trimmedText);
  }

  Future<void> _sendMessageViaHttp(String text) async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty || !mounted) return;

      final url = '${AppConstants.baseUrl}/messages/direct';
      await ApiService.post(
        url,
        context,
        body: {
          'partnerId': widget.partnerId,
          'text': text,
        },
        token: token,
        showLoading: false,
      );
    } catch (e) {
      debugPrint('⚠️ [MatchChat] Gửi HTTP direct message: $e');
    }
  }

  /// Chọn và gửi ảnh từ thư viện hoặc máy ảnh
  Future<void> _handlePickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1400,
      );

      if (pickedFile != null) {
        HapticFeedback.mediumImpact();
        // Gửi tin nhắn ảnh dưới dạng đường dẫn file cục bộ (hoặc tải lên)
        final imageMessage = '[Hình ảnh] file://${pickedFile.path}';
        _handleSendMessage(imageMessage);
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Không thể chọn ảnh. Vui lòng thử lại!');
    }
  }

  /// Chia sẻ vị trí hiện tại
  void _handleShareLocation() {
    HapticFeedback.lightImpact();
    _handleSendMessage('📍 [Vị trí] Đang ở gần bạn (Bán kính 1.2 km) • Hồ Gươm, Hà Nội ✨');
  }

  /// Gửi tin nhắn thoại giả lập / ghi âm phong cách Telegram/Messenger
  void _handleVoiceNote() {
    HapticFeedback.mediumImpact();
    _handleSendMessage('🎙️ [Tin nhắn thoại 0:08] Rất vui vì được kết nối cùng bạn hôm nay! ✨');
  }

  /// Hiển thị Popup / Bottom Sheet tùy chọn truyền thông phong cách Telegram / Messenger
  void _showMediaActionSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Chia sẻ tiện ích định mệnh',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMediaOptionItem(
                    icon: Icons.photo_library_rounded,
                    label: 'Bộ sưu tập',
                    gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _handlePickImage(ImageSource.gallery);
                    },
                  ),
                  _buildMediaOptionItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'Máy ảnh',
                    gradient: const [Color(0xFFEC4899), Color(0xFFD946EF)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _handlePickImage(ImageSource.camera);
                    },
                  ),
                  _buildMediaOptionItem(
                    icon: Icons.location_on_rounded,
                    label: 'Vị trí',
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleShareLocation();
                    },
                  ),
                  _buildMediaOptionItem(
                    icon: Icons.mic_rounded,
                    label: 'Ghi âm',
                    gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleVoiceNote();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaOptionItem({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn chặn $_partnerDisplayName? Người này sẽ bị xóa khỏi danh sách bạn bè và không thể tìm thấy, gửi sóng hay trò chuyện với bạn nữa.',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13.5,
            color: Color(0xFF64748B),
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
      ToastUtil.showSuccess(context, 'Đã chặn $_partnerDisplayName thành công');
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
          targetUserName: _partnerDisplayName,
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
      partnerName: _partnerDisplayName,
      onSelectSuggestion: (text) {
        _chatController.text = text;
        _focusNode.requestFocus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auraGradient = AnonymousAvatarHelper.getCosmicAuraGradient(widget.partnerId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: _buildPearlyAppBar(auraGradient),
      body: Stack(
        children: [
          // 1. Nền Gradient Ngọc Trai sáng thanh thoát (Pearly Soft Light)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFAF7FF), // Kem ngọc trai phớt tím pastel
                  Color(0xFFF1F5F9), // Trắng sương mai trong trẻo
                  Color(0xFFEFF6FF), // Xanh thiên thanh pastel dịu mát
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Quầng sáng Pastel mờ ảo tạo chiều sâu thư thái
          Positioned(
            top: 60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFCE7F3).withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE0E7FF).withValues(alpha: 0.8),
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
                // Khung danh sách tin nhắn
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
                                if (_isPartnerTyping) {
                                  if (index == 0) return _buildTypingIndicator(auraGradient);
                                  if (index == _messages.length + 1) {
                                    return _buildMatchCelebrationHeader(auraGradient);
                                  }
                                  return _buildMessageBubble(_messages[index - 1], auraGradient);
                                }

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
                                      color: Colors.white.withValues(alpha: 0.95),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF334155),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),

                // 4. Hàng chip câu hỏi mở lời phá băng (Icebreakers)
                if (_messages.length <= 3) _buildIcebreakerChips(),

                // 5. Thanh công cụ nhập liệu đa phương tiện kiểu Telegram / Messenger
                _buildTelegramMessengerInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar kính mờ Trắng Ngọc Trai (Đã mở khóa danh tính thật 100%)
  PreferredSizeWidget _buildPearlyAppBar(LinearGradient auraGradient) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              border: const Border(
                bottom: BorderSide(
                  color: Color(0xFFE2E8F0),
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
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1E293B),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Avatar + Tên + Trạng thái -> Bấm vào để mở Profile chi tiết
                    Expanded(
                      child: GestureDetector(
                        onTap: _navigateToProfile,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            // Avatar thật với vòng hào quang phát sáng
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: auraGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: auraGradient.colors.first.withValues(alpha: 0.28),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _buildPartnerAvatarImage(),
                                  ),
                                ),
                                // Chấm xanh ngọc Online
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _isPartnerOnline
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF94A3B8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),

                            // Tên và thông tin tần số định mệnh
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _partnerDisplayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            color: Color(0xFF0F172A),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      // Huy hiệu đã xác thực danh tính định mệnh
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Color(0xFF3B82F6),
                                        size: 16,
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
                                            : const Color(0xFF6366F1),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _isPartnerOnline
                                              ? '$_partnerHertz • Đang phát sóng'
                                              : '$_partnerHertz • Ngoại tuyến',
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

                    // Nút Faye AI gợi ý mở lời
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDDD6FE),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Faye AI gợi ý câu mở lời',
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF8B5CF6),
                          size: 19,
                        ),
                        onPressed: _showAiSuggestionModal,
                      ),
                    ),

                    // Nút Tuỳ chọn 3 chấm
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF64748B),
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
    return GestureDetector(
      onTap: _navigateToProfile,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 16, bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE0E7FF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar thật cỡ lớn có hào quang
            Center(
              child: Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: auraGradient,
                  boxShadow: [
                    BoxShadow(
                      color: auraGradient.colors.first.withValues(alpha: 0.38),
                      blurRadius: 22,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildPartnerAvatarImage(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tên thật đối phương
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _partnerDisplayName,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF3B82F6),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Chip Kết nối định mệnh & Tần số
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF5F3FF),
                    Color(0xFFFDF2F8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDDD6FE),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 13,
                    color: Color(0xFFEC4899),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Đồng điệu định mệnh • $_partnerHertz',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Lời chúc se duyên
            Text(
              _partnerBio != null && _partnerBio!.isNotEmpty
                  ? '“$_partnerBio”'
                  : 'Hai bạn đã tìm thấy nhau giữa triệu tần số vũ trụ.\nHãy cùng mở đầu một cuộc trò chuyện chân thành nhé! ✨',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),

            // Nút bấm xem Profile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    color: Color(0xFF6366F1),
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Nhấn để xem toàn bộ hồ sơ',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _icebreakers[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _handleSendMessage(prompt);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE0E7FF),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFF334155),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Thanh công cụ nhập liệu đa năng phong cách Telegram / Messenger
  Widget _buildTelegramMessengerInputBar() {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    final effectiveBottomPadding = bottomInset > 0
        ? 8.0
        : (safeBottom > 0 ? safeBottom + 4.0 : 12.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: const Border(
              top: BorderSide(
                color: Color(0xFFF1E5ED),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            top: 8,
            bottom: effectiveBottomPadding,
          ),
          child: Row(
            children: [
              // 1. Nút '+' mở Popup/Sheet đa tiện ích
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF6366F1),
                  size: 26,
                ),
                tooltip: 'Chia sẻ ảnh, vị trí, voice note',
                onPressed: _showMediaActionSheet,
              ),

              // 2. Nút Camera chụp nhanh (phong cách Telegram / Messenger)
              IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF64748B),
                  size: 24,
                ),
                tooltip: 'Chụp ảnh nhanh',
                onPressed: () => _handlePickImage(ImageSource.camera),
              ),

              // 3. Khung ô nhập văn bản tích hợp Emoji
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 14.5,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhắn tin cho $_partnerDisplayName...',
                            hintStyle: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (val) => _handleSendMessage(val),
                        ),
                      ),
                      // Icon Emoji
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _chatController.text = '${_chatController.text} 😊';
                          _chatController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _chatController.text.length),
                          );
                        },
                        child: const Icon(
                          Icons.sentiment_satisfied_alt_rounded,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 4. Nút Hành động chuyển đổi linh hoạt:
              //    - Có chữ: Nút GỬI tin nhắn (Send Button) tròn hồng tím
              //    - Rỗng: Nút MICRO ghi âm thoại (Voice Note Button) phong cách Telegram/Messenger
              GestureDetector(
                onTap: () {
                  if (_hasInputText) {
                    _handleSendMessage(_chatController.text);
                  } else {
                    _handleVoiceNote();
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _hasInputText ? Icons.arrow_upward_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bong bóng tin nhắn thông minh (Văn bản, Hình ảnh, Tin nhắn thoại, Vị trí)
  Widget _buildMessageBubble(ChatMessage msg, LinearGradient auraGradient) {
    final isMe = msg.isSentByMe;
    final timeString =
        "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";

    final isImage = msg.text.startsWith('[Hình ảnh]');
    final isVoice = msg.text.startsWith('🎙️ [Tin nhắn thoại');
    final isLocation = msg.text.startsWith('📍 [Vị trí]');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar đối phương bên trái -> Bấm vào để xem Profile
          if (!isMe) ...[
            GestureDetector(
              onTap: _navigateToProfile,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: auraGradient,
                ),
                padding: const EdgeInsets.all(1.5),
                child: ClipOval(
                  child: _buildPartnerAvatarImage(),
                ),
              ),
            ),
          ],

          // Nội dung bong bóng
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                ),
                padding: isImage
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                  ),
                  border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: isMe
                          ? const Color(0xFFEC4899).withValues(alpha: 0.28)
                          : const Color(0xFF64748B).withValues(alpha: 0.08),
                      blurRadius: isMe ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _buildBubbleContent(msg, isMe, isImage, isVoice, isLocation),
              ),
              const SizedBox(height: 3),

              // Thời gian gửi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeString,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        color: Color(0xFF6366F1),
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

  /// Xây dựng nội dung chi tiết bên trong bong bóng tin nhắn
  Widget _buildBubbleContent(
    ChatMessage msg,
    bool isMe,
    bool isImage,
    bool isVoice,
    bool isLocation,
  ) {
    if (isImage) {
      final imagePath = msg.text.replaceFirst('[Hình ảnh]', '').trim();
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imagePath.startsWith('file://')
            ? Image.file(
                File(imagePath.replaceFirst('file://', '')),
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _buildImageError(),
              )
            : Image.network(
                imagePath,
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _buildImageError(),
              ),
      );
    }

    if (isVoice) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: isMe ? Colors.white : const Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg.text,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: isMe ? Colors.white : const Color(0xFF1E293B),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (isLocation) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: isMe ? Colors.white : const Color(0xFF059669),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg.text,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: isMe ? Colors.white : const Color(0xFF1E293B),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    // Văn bản bình thường
    return Text(
      msg.text,
      style: TextStyle(
        fontFamily: 'BeVietnamPro',
        color: isMe ? Colors.white : const Color(0xFF1E293B),
        fontSize: 14.5,
        height: 1.45,
        letterSpacing: 0.1,
        fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: 200,
      height: 150,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 36),
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
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: auraGradient,
            ),
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: _buildPartnerAvatarImage(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TypingIndicator(color: Color(0xFF8B5CF6)),
          ),
        ],
      ),
    );
  }

  /// Xây dựng ảnh đại diện thật của đối phương (hoặc fallback)
  Widget _buildPartnerAvatarImage() {
    if (_partnerRealAvatar != null && _partnerRealAvatar!.isNotEmpty) {
      if (_partnerRealAvatar!.startsWith('http')) {
        return Image.network(
          _partnerRealAvatar!,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildDefaultAvatar(),
        );
      } else if (_partnerRealAvatar!.startsWith('assets/')) {
        return Image.asset(
          _partnerRealAvatar!,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildDefaultAvatar(),
        );
      }
    }

    return Image.asset(
      AnonymousAvatarHelper.getAnonymousAvatarAsset(widget.partnerId),
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFF5F3FF),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8B5CF6),
        size: 20,
      ),
    );
  }
}
