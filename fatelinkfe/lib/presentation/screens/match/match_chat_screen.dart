import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/services/image_picker_service.dart';

import '../../../core/utils/anonymous_avatar_helper.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/match_user.dart';
import '../../../presentation/widgets/typing_indicator.dart';
import '../../../services/api_service.dart';
import '../../../services/badge_service.dart';
import '../../../services/app_socket_service.dart';
import '../../../services/call_manager.dart';

// Components & Widgets tách rời sạch sẽ
import '../../widgets/cosmic_report_modal.dart';
import '../profile/user_detail_screen.dart';
import 'widgets/cosmic_incoming_call_modal.dart';
import 'widgets/cosmic_location_modal.dart';
import 'widgets/cosmic_voice_call_modal.dart';
import 'widgets/glassmorphic_card_stack.dart';
import 'widgets/glassmorphic_image_viewer.dart';
import 'widgets/match_ai_suggestion_sheet.dart';
import 'widgets/match_options_bottom_sheet.dart';
import 'widgets/cosmic_emoji_picker_sheet.dart';
import 'widgets/cosmic_voice_player_bubble.dart';
import 'widgets/telegram_voice_recorder_bar.dart';
import 'widgets/meyufeel_resonance_bar.dart';
import 'widgets/meyufeel_watermark_lotus.dart';
import '../../../core/services/voice_note_service.dart';
import '../../../core/services/voice_player_manager.dart';

/// Màn hình trò chuyện ghép đôi FateLink (MatchChatScreen):
/// - Vấn đề 1: Thả react (❤️, 🔥, 😂, 😮, 😢, 👍), Trả lời trích dẫn (Reply/Quote),
///             Gỡ/Thu hồi tin nhắn ("Xóa ở tôi" & "Thu hồi với mọi người"),
///             Chọn nhiều tin nhắn để xóa cùng lúc (Multi-select Mode).
/// - Vấn đề 2 & 4.1: Gửi nhiều ảnh cùng lúc qua `pickMultiImage()`.
///                   Hiển thị đoạn chat dạng "Modern Glassmorphic Card Stack UI"
///                   với card xếp lớp 3D bo góc lớn 22px, viền kính mờ, soft shadow.
///                   Nhấn vào ảnh để xem trọn vẹn phóng to (`GlassmorphicImageViewer`).
/// - Vấn đề 3: Đàm thoại trực tiếp qua mic với sóng âm Soulmate (`CosmicVoiceCallModal`).
/// - Vấn đề 4.3: Chia sẻ vị trí thực tế (`CosmicLocationPickerModal`) với bản đồ radar,
///               tọa độ GPS và địa chỉ chi tiết (không còn mock thô sơ).
/// - Vấn đề 4.4: Ghi âm giọng nói thực tế (`CosmicVoiceRecorderModal`) với sóng âm chuyển động.
/// - Vấn đề 5: Bỏ tích xanh cạnh tên ở cả AppBar và Header se duyên.
/// - Tính năng Soulmate & Giữ lửa 🔥: Thanh Soulmate Resonance Bar hiển thị chuỗi giữ lửa
///   và mức độ thấu hiểu tâm giao, mở rộng bản đồ kết nối cảm xúc.
/// - UI/UX: Siêu mềm mại, bo góc 22-26px, đa tầng glassmorphism, micro-interactions chuẩn Apple.
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
    this.canViewIdentity = true,
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
  StreamSubscription? _directMessageSub;
  StreamSubscription? _reconnectSub;

  bool _isPartnerTyping = false;
  bool _isPartnerOnline = false;
  bool _isLoadingHistory = false;
  bool _isNearBottom = true;
  int _unreadCount = 0;
  bool _hasInputText = false;
  bool _isSyncing = false;
  bool _isEmojiPickerVisible = false;
  bool _isRecordingVoice = false;

  // Trạng thái Reply & Multi-select & Cuộc gọi
  ChatMessage? _replyingMessage;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessageIds = {};
  dynamic _pendingOfferSdp;

  // Thông tin thực tế đối phương nạp từ API Profile
  late String _partnerDisplayName;
  String? _partnerRealAvatar;
  String? _partnerBio;
  String? _partnerEmotion;
  String? _partnerHertz;
  String? _partnerMoodIcon;
  MatchUser? _partnerUserObject;

  // Danh sách tin nhắn cuộc trò chuyện
  final List<ChatMessage> _messages = [];

  // Gợi ý mở lời phá băng (Icebreakers) ngọt ngào
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

    _focusNode.addListener(_onFocusChanged);
    _scrollController.addListener(_scrollListener);
    _chatController.addListener(_onTextChanged);

    // Đánh dấu người dùng đang mở phòng chat với partnerId này (để không tăng unread badge)
    AppSocketService().setActiveChatPartner(widget.partnerId);

    // Khi người dùng vào xem phòng chat, xóa sạch badge icon app
    BadgeService.clearBadge();

    // Tin nhắn mở đầu se duyên mặc định
    _messages.add(
      ChatMessage(
        text: 'Xin chào! Rất vui vì định mệnh đã kết nối chúng ta hôm nay ✨',
        isSentByMe: false,
        timestamp: DateTime.now(),
      ),
    );

    // 1. Tải Profile thực tế đối phương
    _fetchPartnerProfile();

    // 2. Tải lịch sử và khởi tạo Socket.IO
    _isLoadingHistory = true;
    _historyTimeoutTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _isLoadingHistory) {
        setState(() => _isLoadingHistory = false);
      }
    });

    _initSocketAndLoadHistory();

    // 3. Fallback Polling dự phòng nhẹ nhàng mỗi 12s
    _pollingFallbackTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted && (_socket == null || !_socket!.connected)) {
        _syncMessagesViaHttp();
      }
    });
  }

  void _onTextChanged() {
    final hasText = _chatController.text.trim().isNotEmpty;
    if (hasText != _hasInputText) {
      setState(() => _hasInputText = hasText);
    }

    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {
        'partnerId': widget.partnerId,
        'isTyping': hasText,
      });

      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        if (_socket != null && _socket!.connected) {
          _socket!.emit('typing', {
            'partnerId': widget.partnerId,
            'isTyping': false,
          });
        }
      });
    }
  }

  /// Tải thông tin hồ sơ đối phương
  Future<void> _fetchPartnerProfile() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty || !mounted) return;

      final url = '${AppConstants.baseUrl}/users/${widget.partnerId}/profile';
      final res = await ApiService.get(url, context, token: token, showLoading: false);

      if (res != null && mounted) {
        final profileData = res is Map ? res : {};
        setState(() {
          _partnerDisplayName = profileData['name'] ?? profileData['fullName'] ?? widget.partnerName;
          _partnerRealAvatar = profileData['avatar'] ?? profileData['avatarUrl'] ?? widget.partnerAvatar;
          _partnerBio = profileData['bio'] ?? profileData['about'];
          _partnerEmotion = profileData['emotion'] ?? profileData['currentMood'];
          _partnerHertz = profileData['frequencyHertz'] ?? widget.frequencyHertz ?? '528 Hz';
          _partnerMoodIcon = profileData['moodIcon'] ?? widget.moodIcon ?? '✨';

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

  /// Khởi tạo kết nối Socket và nạp tin nhắn
  Future<void> _initSocketAndLoadHistory() async {
    try {
      // 1. Đảm bảo AppSocketService đã kết nối
      await AppSocketService().initialize();
      _socket = AppSocketService().socket;

      // 2. Lắng nghe tin nhắn trực tiếp từ AppSocketService
      _directMessageSub?.cancel();
      _directMessageSub = AppSocketService().directMessageStream.listen((data) {
        if (!mounted) return;
        if (data['senderId'] == widget.partnerId) {
          HapticFeedback.lightImpact();
          final chatMsg = ChatMessage.fromJson(Map<String, dynamic>.from(data));

          final senderId = data['senderId']?.toString() ?? '';
          debugPrint(
            '📩 [Socket Receive] bên nhận: receiveDirectMessage: id=${chatMsg.id}, senderId=$senderId, text=${chatMsg.text.length > 30 ? chatMsg.text.substring(0, 30) : chatMsg.text}',
          );

          setState(() {
            _isPartnerTyping = false;
            final isDuplicate = _messages.any((m) =>
                (chatMsg.id.isNotEmpty && m.id == chatMsg.id) ||
                (m.text == chatMsg.text &&
                    m.isSentByMe == chatMsg.isSentByMe &&
                    m.timestamp.difference(chatMsg.timestamp).abs().inSeconds < 5));
            if (!isDuplicate) {
              _messages.insert(0, chatMsg);
              if (!_isNearBottom) {
                _unreadCount++;
              }
            }
          });
          if (_isNearBottom) {
            _scrollToBottom();
          }
        }
      });

      // 3. Lắng nghe Reconnect để đồng bộ tin nhắn đã lỡ
      _reconnectSub?.cancel();
      _reconnectSub = AppSocketService().reconnectStream.listen((_) {
        debugPrint('🔄 [MatchChat] Socket reconnect -> Thực hiện đồng bộ tin nhắn đã lỡ');
        _syncMissedMessages();
      });

      if (_socket != null) {
        _socket!.off('directHistoryResult');
        _socket!.off('receiveTyping');
        _socket!.off('userStatusResult');
        _socket!.off('userStatusChanged');

        _socket!.on('directHistoryResult', (data) {
          if (!mounted) return;
          _historyTimeoutTimer?.cancel();

          if (data is Map && data['partnerId'] == widget.partnerId) {
            final rawMessages = data['messages'] as List? ?? [];
            final List<ChatMessage> loaded = [];

            for (final item in rawMessages) {
              if (item is Map) {
                final chatMsg = ChatMessage.fromJson(Map<String, dynamic>.from(item));
                loaded.add(chatMsg);
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

        if (_socket!.connected) {
          _socket!.emit('loadDirectHistory', {
            'partnerId': widget.partnerId,
            'limit': 50,
          });

          _socket!.emit('checkUserStatus', {
            'targetUserId': widget.partnerId,
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MatchChatSocket] Lỗi khởi tạo socket: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  /// Đồng bộ tin nhắn bị lỡ khi socket reconnect
  Future<void> _syncMissedMessages() async {
    if (!mounted) return;
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty) return;

      DateTime? latestTimestamp;
      for (final m in _messages) {
        if (latestTimestamp == null || m.timestamp.isAfter(latestTimestamp)) {
          latestTimestamp = m.timestamp;
        }
      }

      final queryParam = latestTimestamp != null
          ? '?after=${Uri.encodeComponent(latestTimestamp.toUtc().toIso8601String())}'
          : '';
      final url = '${AppConstants.baseUrl}/messages/direct/${widget.partnerId}$queryParam';
      debugPrint('🔄 [MatchChat Sync] Gọi incremental sync: GET $url');
      final res = await ApiService.get(url, context, token: token, showLoading: false);

      if (res is List && mounted) {
        final List<ChatMessage> newOnes = [];
        for (final item in res) {
          if (item is Map) {
            final msg = ChatMessage.fromJson(Map<String, dynamic>.from(item));
            final exists = _messages.any((m) =>
                m.id == msg.id ||
                (m.text == msg.text &&
                    m.isSentByMe == msg.isSentByMe &&
                    m.timestamp.difference(msg.timestamp).abs().inSeconds < 5));
            if (!exists) {
              newOnes.add(msg);
            }
          }
        }
        if (newOnes.isNotEmpty) {
          debugPrint('✅ [MatchChat Sync] Đã nhận ${newOnes.length} tin nhắn bị lỡ');
          setState(() {
            for (final msg in newOnes) {
              _messages.insert(0, msg);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MatchChat Sync] Lỗi sync reconnect: $e');
    }
  }

  /// Đồng bộ tin nhắn qua REST API HTTP
  Future<void> _syncMessagesViaHttp() async {
    if (_isSyncing || !mounted) return;
    _isSyncing = true;

    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty || !mounted) return;

      final url = '${AppConstants.baseUrl}/messages/direct/${widget.partnerId}';
      final res = await ApiService.get(url, context, token: token, showLoading: false);

      if (res is List && mounted) {
        final List<ChatMessage> loaded = [];
        for (final item in res) {
          if (item is Map) {
            final chatMsg = ChatMessage.fromJson(Map<String, dynamic>.from(item));
            loaded.add(chatMsg);
          }
        }

        if (loaded.isNotEmpty) {
          setState(() {
            for (final msg in loaded) {
              final alreadyExists = _messages.any((existing) =>
                  existing.text == msg.text &&
                  existing.isSentByMe == msg.isSentByMe &&
                  existing.timestamp.difference(msg.timestamp).abs().inSeconds < 5);
              if (!alreadyExists) {
                _messages.insert(0, msg);
              }
            }
            _isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MatchChat] Lỗi sync HTTP messages: $e');
    } finally {
      _isSyncing = false;
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final cleanToken = token.replaceFirst(RegExp(r'^Bearer\s+'), '').trim();
      final parts = cleanToken.split('.');
      if (parts.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      if (exp == null) return false;
      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expDate.subtract(const Duration(seconds: 60)));
    } catch (_) {
      return true;
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _isEmojiPickerVisible) {
      setState(() => _isEmojiPickerVisible = false);
    }
  }

  void _scrollListener() {
    if (_isEmojiPickerVisible) {
      setState(() => _isEmojiPickerVisible = false);
    }
    if (!_scrollController.hasClients) return;

    final isNearBottom = _scrollController.offset <= 100.0;
    if (_isNearBottom != isNearBottom) {
      setState(() => _isNearBottom = isNearBottom);
    }
    if (isNearBottom && _unreadCount > 0) {
      setState(() => _unreadCount = 0);
    }
  }

  void _toggleEmojiPicker() {
    HapticFeedback.lightImpact();
    if (_isEmojiPickerVisible) {
      setState(() => _isEmojiPickerVisible = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _isEmojiPickerVisible = true);
    }
  }

  void _insertEmoji(String emoji) {
    final text = _chatController.text;
    final selection = _chatController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _chatController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _handleEmojiBackspace() {
    final text = _chatController.text;
    final selection = _chatController.selection;
    if (text.isEmpty) return;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    if (start != end) {
      final newText = text.replaceRange(start, end, '');
      _chatController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      final runes = text.runes.toList();
      runes.removeLast();
      final newText = String.fromCharCodes(runes);
      _chatController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
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

  /// Nút mũi tên nổi cuộn xuống tin nhắn mới nhất phong cách Messenger / Telegram
  Widget _buildScrollToBottomButton() {
    return Positioned(
      bottom: 12,
      right: 16,
      child: AnimatedScale(
        scale: !_isNearBottom ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: !_isNearBottom ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: _isNearBottom,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(21),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _scrollToBottom();
                        if (_unreadCount > 0) {
                          setState(() => _unreadCount = 0);
                        }
                      },
                      child: const Center(
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF6366F1),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _historyTimeoutTimer?.cancel();
    _typingDebounce?.cancel();
    _pollingFallbackTimer?.cancel();
    _directMessageSub?.cancel();
    _reconnectSub?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _scrollController.removeListener(_scrollListener);
    _chatController.removeListener(_onTextChanged);

    // Bỏ đăng ký phòng chat đang mở
    AppSocketService().setActiveChatPartner(null);

    // Dừng phát âm thanh và hủy ghi âm nếu màn hình bị đóng
    VoicePlayerManager().stopAll();
    VoiceNoteService().cancelRecording();

    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {
        'partnerId': widget.partnerId,
        'isTyping': false,
      });
    }

    _chatController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Xem Profile chi tiết đối phương
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

  /// Gửi tin nhắn thực tế (Văn bản / Trả lời trích dẫn)
  void _handleSendMessage(
    String text, {
    String? messageType,
    List<String>? imageUrls,
  }) {
    if (text.trim().isEmpty && (imageUrls == null || imageUrls.isEmpty)) return;
    HapticFeedback.lightImpact();

    final trimmedText = text.trim();
    final replyText = _replyingMessage?.text;
    final replySender = _replyingMessage != null
        ? (_replyingMessage!.isSentByMe ? 'Chính bạn' : _partnerDisplayName)
        : null;

    final clientMsgId = '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000000)}';
    final newMessage = ChatMessage(
      id: clientMsgId,
      text: trimmedText,
      isSentByMe: true,
      timestamp: DateTime.now(),
      replyToText: replyText,
      replyToSender: replySender,
      imageUrls: imageUrls ?? const [],
      messageType: messageType ?? (imageUrls != null && imageUrls.length > 1 ? 'imageStack' : 'text'),
      isSending: true,
      isSendError: false,
    );

    // 1. Thêm tin nhắn của mình vào UI tức thời (0ms Latency) với trạng thái ĐANG GỬI
    setState(() {
      _messages.insert(0, newMessage);
      _replyingMessage = null; // Clear reply sau khi gửi
    });

    _chatController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 2. Gửi qua Socket có Ack callback và Timeout 8s
    _dispatchSendMessage(
      newMessage,
      clientMsgId,
      trimmedText,
      replyText,
      replySender,
      imageUrls,
    );
  }

  /// Thực thi gửi tin nhắn qua WebSocket Ack callback (với fallback HTTP nếu socket ngắt hẳn)
  Future<void> _dispatchSendMessage(
    ChatMessage msg,
    String clientMsgId,
    String text,
    String? replyText,
    String? replySender,
    List<String>? imageUrls,
  ) async {
    try {
      final ack = await AppSocketService().sendDirectMessageWithAck(
        partnerId: widget.partnerId,
        text: text,
        messageType: msg.messageType,
        imageUrls: imageUrls,
        clientMessageId: clientMsgId,
      );

      debugPrint(
        '📥 [Socket Ack] nhận được (id server: ${ack['id']}, clientMsgId: ${ack['clientMessageId']})',
      );

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == clientMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              id: ack['id']?.toString() ?? clientMsgId,
              isSending: false,
              isSendError: false,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ [Socket Send Error] Lỗi hoặc timeout sau 8s: $e');
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == clientMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              isSending: false,
              isSendError: true,
            );
          }
        });
      }
    }
  }

  /// Thử lại gửi tin nhắn khi bị lỗi (cùng clientMessageId cũ)
  void _retrySendMessage(ChatMessage msg) {
    HapticFeedback.lightImpact();
    if (msg.isVoice) {
      _retrySendVoiceMessage(msg);
    } else if (msg.messageType == 'image' || msg.messageType == 'imageStack') {
      _retrySendImageMessage(msg);
    } else {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            isSending: true,
            isSendError: false,
          );
        }
      });
      _dispatchSendMessage(
        msg,
        msg.id,
        msg.text,
        msg.replyToText,
        msg.replyToSender,
        msg.imageUrls.isNotEmpty ? msg.imageUrls : null,
      );
    }
  }

  Future<void> _sendMessageViaHttp(
    String text,
    String? replyText,
    String? replySender, {
    List<String>? imageUrls,
    String? messageType,
    String? mediaUrl,
    int? durationMs,
    List<int>? waveform,
    String? clientMessageId,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty || !mounted) return;

      final url = '${AppConstants.baseUrl}/messages/direct';
      final body = <String, dynamic>{
        'partnerId': widget.partnerId,
        'text': text,
        if (replyText != null) 'replyToText': replyText,
        if (replySender != null) 'replyToSender': replySender,
        if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        if (messageType != null) 'messageType': messageType,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (durationMs != null) 'durationMs': durationMs,
        if (waveform != null && waveform.isNotEmpty) 'waveform': waveform,
        if (clientMessageId != null) 'clientMessageId': clientMessageId,
      };

      await ApiService.post(
        url,
        context,
        body: body,
        token: token,
        showLoading: false,
      );
    } catch (e) {
      debugPrint('⚠️ [MatchChat] Gửi HTTP direct message: $e');
    }
  }

  /// Vấn đề 2 & 4.1: Chọn và gửi nhiều ảnh cùng lúc qua `pickMultiImage()`
  Future<void> _handlePickMultiImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (pickedFiles.isNotEmpty) {
        HapticFeedback.mediumImpact();
        final rawPaths = pickedFiles.map((f) => f.path).toList();
        final previewPaths = pickedFiles.map((f) => 'file://${f.path}').toList();
        final isStack = rawPaths.length > 1;

        final tempId = 'temp_img_${DateTime.now().millisecondsSinceEpoch}';
        final newMessage = ChatMessage(
          id: tempId,
          text: isStack ? '[Bộ sưu tập ${rawPaths.length} ảnh]' : '[Hình ảnh]',
          isSentByMe: true,
          timestamp: DateTime.now(),
          imageUrls: previewPaths,
          messageType: isStack ? 'imageStack' : 'image',
          localFilePath: rawPaths.join('|'),
          isSending: true,
          isSendError: false,
        );

        setState(() {
          _messages.insert(0, newMessage);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        _uploadAndSendImageMessage(newMessage, rawPaths);
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Không thể chọn ảnh. Vui lòng thử lại!');
    }
  }

  /// Chụp ảnh nhanh từ máy ảnh
  Future<void> _handlePickCamera() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (picked != null) {
        HapticFeedback.mediumImpact();
        final rawPath = picked.path;
        final previewPath = 'file://${picked.path}';

        final tempId = 'temp_img_${DateTime.now().millisecondsSinceEpoch}';
        final newMessage = ChatMessage(
          id: tempId,
          text: '[Hình ảnh]',
          isSentByMe: true,
          timestamp: DateTime.now(),
          imageUrls: [previewPath],
          messageType: 'image',
          localFilePath: rawPath,
          isSending: true,
          isSendError: false,
        );

        setState(() {
          _messages.insert(0, newMessage);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        _uploadAndSendImageMessage(newMessage, [rawPath]);
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Không thể mở máy ảnh. Vui lòng kiểm tra quyền!');
    }
  }

  /// Tải ảnh lên Cloudinary trước, có HTTPS URL mới gửi tin nhắn (Không gửi đường dẫn file://)
  Future<void> _uploadAndSendImageMessage(ChatMessage msg, List<String> rawPaths) async {
    try {
      final List<String> uploadedUrls = [];
      for (final path in rawPaths) {
        final cloudUrl = await ImagePickerService.uploadToCloudinary(
          context,
          path,
          folder: 'fatelink/chat_images',
        );
        if (cloudUrl == null || cloudUrl.isEmpty) {
          throw Exception('Upload ảnh thất bại: $path');
        }
        uploadedUrls.add(cloudUrl);
      }

      if (!mounted) return;

      final isStack = uploadedUrls.length > 1;
      final textContent = isStack ? '[Bộ sưu tập ${uploadedUrls.length} ảnh]' : '[Hình ảnh]';
      final msgType = isStack ? 'imageStack' : 'image';
      final clientMsgId = '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000000)}';

      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            text: textContent,
            imageUrls: uploadedUrls,
            messageType: msgType,
            isSending: true,
            isSendError: false,
          );
        }
      });

      try {
        final ack = await AppSocketService().sendDirectMessageWithAck(
          partnerId: widget.partnerId,
          text: textContent,
          imageUrls: uploadedUrls,
          messageType: msgType,
          clientMessageId: clientMsgId,
        );

        debugPrint(
          '📥 [Socket Ack] nhận được (id server: ${ack['id']}, clientMsgId: ${ack['clientMessageId']})',
        );

        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id || m.id == clientMsgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                id: ack['id']?.toString() ?? msg.id,
                isSending: false,
                isSendError: false,
              );
            }
          });
        }
      } catch (err) {
        debugPrint('❌ [Image Socket Error] Gửi ảnh thất bại hoặc timeout sau 8s: $err');
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                isSending: false,
                isSendError: true,
              );
            }
          });
          ToastUtil.showError(context, 'Tải ảnh lên thất bại. Chạm vào ảnh để thử lại!');
        }
      }
    } catch (e) {
      debugPrint('❌ [ChatImages] Lỗi upload ảnh: $e');
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msg.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              isSending: false,
              isSendError: true,
            );
          }
        });
        ToastUtil.showError(context, 'Tải ảnh lên thất bại. Chạm vào ảnh để thử lại!');
      }
    }
  }

  void _retrySendImageMessage(ChatMessage msg) {
    if (msg.localFilePath == null || msg.localFilePath!.isEmpty) {
      ToastUtil.showError(context, 'Tệp gốc không còn tồn tại trên máy!');
      return;
    }
    final paths = msg.localFilePath!.split('|');
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(
          isSending: true,
          isSendError: false,
        );
      }
    });
    _uploadAndSendImageMessage(msg, paths);
  }

  /// Vấn đề 4.3: Mở modal chia sẻ vị trí thực tế
  void _handleShareLocation() {
    CosmicLocationPickerModal.show(
      context,
      onLocationSelected: (locationText, address, lat, lng) {
        _handleSendMessage(
          locationText,
          messageType: 'location',
        );
      },
    );
  }

  /// Kích hoạt chế độ ghi âm Telegram Voice Note
  void _handleVoiceNote() {
    setState(() => _isRecordingVoice = true);
  }

  /// Xử lý khi thu âm hoàn tất từ Telegram Voice Recorder Bar
  void _handleVoiceRecordComplete(VoiceRecordResult result) {
    HapticFeedback.lightImpact();
    final tempId = 'temp_voice_${DateTime.now().millisecondsSinceEpoch}';
    final newMessage = ChatMessage(
      id: tempId,
      text: '🎙️ Tin nhắn thoại',
      isSentByMe: true,
      timestamp: DateTime.now(),
      messageType: 'voice',
      durationMs: result.durationMs,
      waveform: result.waveform,
      localFilePath: result.localPath,
      isSending: true,
      isSendError: false,
    );

    setState(() {
      _isRecordingVoice = false;
      _messages.insert(0, newMessage);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Bắt đầu upload và gửi nền
    _uploadAndSendVoiceMessage(newMessage);
  }

  /// Upload file ghi âm qua multipart và gửi qua Socket có Ack callback
  Future<void> _uploadAndSendVoiceMessage(ChatMessage msg) async {
    final filePath = msg.localFilePath;
    if (filePath == null || filePath.isEmpty) {
      debugPrint('⚠️ [VoiceNote] Không tìm thấy file ghi âm cục bộ để upload');
      _markVoiceMessageError(msg.id);
      return;
    }

    debugPrint('🎙️ [VoiceNote] Bắt đầu tải lên: $filePath (${msg.durationMs}ms)');
    try {
      final cloudUrl = await VoiceNoteService().uploadVoiceNote(
        filePath,
        context: context,
      );

      if (!mounted) return;

      if (cloudUrl == null || cloudUrl.isEmpty) {
        debugPrint('❌ [VoiceNote] Upload thất bại -> Không gửi tin, giữ file cục bộ và chờ thử lại');
        _markVoiceMessageError(msg.id);
        return;
      }

      debugPrint('✅ [VoiceNote] Upload thành công Cloudinary: $cloudUrl');
      final voicePayload = jsonEncode({
        'type': 'voice',
        'url': cloudUrl,
        'durationMs': msg.durationMs ?? 3000,
        'waveform': msg.effectiveWaveform,
      });

      // Cập nhật URL trong UI nhưng VẪN GIỮ isSending: true (chờ ack socket)
      setState(() {
        final index = _messages.indexWhere((m) => m.id == msg.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            text: voicePayload,
            mediaUrl: cloudUrl,
            isSending: true,
            isSendError: false,
          );
        }
      });

      final clientMsgId = msg.id.startsWith('temp_voice_')
          ? msg.id
          : '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000000)}';

      try {
        final ack = await AppSocketService().sendDirectMessageWithAck(
          partnerId: widget.partnerId,
          text: voicePayload,
          messageType: 'voice',
          mediaUrl: cloudUrl,
          durationMs: msg.durationMs,
          waveform: msg.effectiveWaveform,
          clientMessageId: clientMsgId,
        );

        debugPrint(
          '📥 [Socket Ack] nhận được (id server: ${ack['id']}, clientMsgId: ${ack['clientMessageId']})',
        );

        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == msg.id || m.id == clientMsgId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(
                id: ack['id']?.toString() ?? msg.id,
                isSending: false,
                isSendError: false,
              );
            }
          });
        }
      } catch (err) {
        debugPrint('❌ [VoiceNote Socket Error] Gửi tin voice thất bại hoặc timeout sau 8s: $err');
        if (mounted) {
          _markVoiceMessageError(msg.id);
        }
      }
    } catch (e) {
      debugPrint('❌ [VoiceNote] Ngoại lệ khi upload voice note: $e');
      if (mounted) {
        _markVoiceMessageError(msg.id);
      }
    }
  }

  void _markVoiceMessageError(String messageId) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isSending: false,
          isSendError: true,
        );
      }
    });
    ToastUtil.showError(context, 'Tải lên tin nhắn thoại thất bại. Chạm vào tin nhắn để thử lại.');
  }

  void _retrySendVoiceMessage(ChatMessage msg) {
    debugPrint('🔄 [VoiceNote] Thử lại gửi tin nhắn thoại: ${msg.id}');
    setState(() {
      final index = _messages.indexWhere((m) => m.id == msg.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isSending: true,
          isSendError: false,
        );
      }
    });
    _uploadAndSendVoiceMessage(msg);
  }

  /// Vấn đề 3: Bật mic và trò chuyện trực tiếp qua cuộc gọi Soulmate Voice Call (WebRTC)
  void _handleStartVoiceCall() {
    VoicePlayerManager().stopAll();
    VoiceNoteService().cancelRecording();
    CallManager.instance.startOutgoingCall(
      partnerId: widget.partnerId,
      partnerName: _partnerDisplayName,
      partnerAvatar: _partnerRealAvatar,
    );
  }

  /// Vấn đề 1: Thả React lên tin nhắn
  void _handleReaction(ChatMessage msg, String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      final index = _messages.indexWhere((m) => m.id == msg.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(reaction: emoji);
      }
    });

    if (_socket != null && _socket!.connected) {
      _socket!.emit('reactMessage', {
        'partnerId': widget.partnerId,
        'messageId': msg.id,
        'reaction': emoji,
      });
    }
  }

  /// Vấn đề 1: Xóa tin nhắn ở chính tôi
  void _handleDeleteForMe(ChatMessage msg) {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.removeWhere((m) => m.id == msg.id);
    });
    ToastUtil.showSuccess(context, 'Đã xóa tin nhắn ở phía bạn');
  }

  /// Vấn đề 1: Thu hồi tin nhắn ở phía mọi người
  void _handleRevokeForEveryone(ChatMessage msg) {
    HapticFeedback.mediumImpact();
    setState(() {
      final index = _messages.indexWhere((m) => m.id == msg.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isRevoked: true,
          text: 'Tin nhắn đã được thu hồi',
        );
      }
    });

    if (_socket != null && _socket!.connected) {
      _socket!.emit('revokeMessage', {
        'partnerId': widget.partnerId,
        'messageId': msg.id,
      });
    }
    ToastUtil.showSuccess(context, 'Đã thu hồi tin nhắn');
  }

  /// Vấn đề 1: Xóa nhiều tin nhắn đã chọn
  void _handleDeleteMultipleMessages(bool revokeForEveryone) {
    HapticFeedback.heavyImpact();
    setState(() {
      if (revokeForEveryone) {
        for (int i = 0; i < _messages.length; i++) {
          if (_selectedMessageIds.contains(_messages[i].id) && _messages[i].isSentByMe) {
            _messages[i] = _messages[i].copyWith(
              isRevoked: true,
              text: 'Tin nhắn đã được thu hồi',
            );
          }
        }
      } else {
        _messages.removeWhere((m) => _selectedMessageIds.contains(m.id));
      }
      _isMultiSelectMode = false;
      _selectedMessageIds.clear();
    });
    ToastUtil.showSuccess(context, revokeForEveryone ? 'Đã thu hồi các tin nhắn được chọn' : 'Đã xóa các tin nhắn được chọn');
  }

  /// Menu hành động khi Long Press vào tin nhắn (Reaction Bar + Reply + Xóa/Thu hồi)
  void _showMessageActionMenu(ChatMessage msg) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedMessageIds.contains(msg.id)) {
          _selectedMessageIds.remove(msg.id);
        } else {
          _selectedMessageIds.add(msg.id);
        }
      });
      return;
    }

    HapticFeedback.mediumImpact();
    final emojis = ['❤️', '🔥', '😂', '😮', '😢', '👍'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo
              Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),

              // 1. Dải thả Reaction Emoji tròn nổi bật
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: emojis.map((emoji) {
                    final isCurrent = msg.reaction == emoji;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleReaction(msg, emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFEDE9FE) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          emoji,
                          style: TextStyle(
                            fontSize: isCurrent ? 26 : 22,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Danh sách hành động: Trả lời, Sao chép, Thu hồi, Xóa, Chọn nhiều
              _buildActionMenuItem(
                icon: Icons.reply_rounded,
                color: const Color(0xFF6366F1),
                title: 'Trả lời tin nhắn này',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyingMessage = msg);
                  _focusNode.requestFocus();
                },
              ),
              if (!msg.isRevoked && !msg.text.startsWith('[Hình ảnh]') && !msg.text.startsWith('[Bộ sưu tập'))
                _buildActionMenuItem(
                  icon: Icons.copy_rounded,
                  color: const Color(0xFF0F172A),
                  title: 'Sao chép nội dung',
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ToastUtil.showSuccess(context, 'Đã sao chép nội dung');
                  },
                ),
              if (msg.isSentByMe && !msg.isRevoked)
                _buildActionMenuItem(
                  icon: Icons.undo_rounded,
                  color: const Color(0xFFD946EF),
                  title: 'Thu hồi ở phía mọi người',
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleRevokeForEveryone(msg);
                  },
                ),
              _buildActionMenuItem(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                title: 'Xóa ở phía tôi',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteForMe(msg);
                },
              ),
              _buildActionMenuItem(
                icon: Icons.checklist_rounded,
                color: const Color(0xFF3B82F6),
                title: 'Chọn nhiều tin nhắn...',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _isMultiSelectMode = true;
                    _selectedMessageIds.add(msg.id);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color == const Color(0xFFEF4444) ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
        ),
      ),
      onTap: onTap,
    );
  }

  /// Sheet tiện ích đa phương tiện (+)
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
                    label: 'Gửi nhiều ảnh',
                    gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _handlePickMultiImages();
                    },
                  ),
                  _buildMediaOptionItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'Máy ảnh',
                    gradient: const [Color(0xFFEC4899), Color(0xFFD946EF)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _handlePickCamera();
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
                    label: 'Ghi âm thoại',
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
      if (token == null || token.isEmpty || !mounted) return;

      final url = '${AppConstants.baseUrl}/matches/unmatch';
      await ApiService.post(
        url,
        context,
        body: {'targetUserId': widget.partnerId},
        token: token,
      );

      if (mounted) {
        ToastUtil.showSuccess(context, 'Đã hủy kết nối ghép đôi');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(context, 'Không thể hủy kết nối. Vui lòng thử lại!');
      }
    }
  }

  void _showReportDialog() {
    CosmicReportModal.show(
      context,
      targetUserId: widget.partnerId,
      targetUserName: _partnerDisplayName,
    );
  }

  void _handleBlock() {
    ToastUtil.showSuccess(context, 'Đã chặn người dùng này');
    Navigator.pop(context);
  }

  void _showOptionsModal() {
    HapticFeedback.lightImpact();
    MatchOptionsBottomSheet.show(
      context,
      onReport: _showReportDialog,
      onUnmatch: _handleUnmatch,
      onBlock: _handleBlock,
    );
  }

  void _showAiSuggestionModal() {
    HapticFeedback.lightImpact();
    // Tìm tin nhắn gần nhất của đối phương để AI suy nghĩ câu trả lời phù hợp
    String? lastPartnerMessage;
    for (final m in _messages) {
      if (!m.isSentByMe && m.text.trim().isNotEmpty) {
        lastPartnerMessage = m.text.trim();
        break;
      }
    }

    // Lấy ngữ cảnh vài tin nhắn gần nhất
    final recentContext = _messages
        .take(5)
        .toList()
        .reversed
        .map((m) =>
            '${m.isSentByMe ? "Tôi" : _partnerDisplayName}: ${m.text.trim()}')
        .where((s) => s.isNotEmpty)
        .toList();

    MatchAiSuggestionSheet.show(
      context,
      partnerName: _partnerDisplayName,
      lastPartnerMessage: lastPartnerMessage,
      recentContext: recentContext,
      onSelectSuggestion: (text) {
        _chatController.text = text;
        _chatController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        _focusNode.requestFocus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const auraGradient = LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _isMultiSelectMode ? _buildMultiSelectAppBar() : _buildStandardAppBar(auraGradient),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Thanh tiến trình MeyuFeel & Ngọn lửa Tinh Vân MeyuFlame (Bắt đầu từ 0%)
            if (!_isMultiSelectMode)
              MeyuFeelResonanceBar(
                streakDays: 3,
                messageCount: _messages.length,
                partnerName: _partnerDisplayName,
                frequencyHertz: _partnerHertz ?? '528 Hz',
              ),

            // Khu vực danh sách tin nhắn
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const MeyuFeelWatermarkLotus(),
                  GestureDetector(
                onTap: () {
                  if (_isEmojiPickerVisible) {
                    setState(() => _isEmojiPickerVisible = false);
                  }
                  FocusScope.of(context).unfocus();
                },
                child: _isLoadingHistory
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildSoulmateConnectionHeader(auraGradient);
                          }
                          final msg = _messages[index];
                          return _buildSelectableMessageBubble(msg, auraGradient);
                        },
                      ),
              ),
              // Nút mũi tên cuộn xuống tin nhắn mới nhất (Scroll to Bottom Messenger style)
              _buildScrollToBottomButton(),
            ],
          ),
        ),

            // Đang nhập văn bản (Typing indicator)
            if (_isPartnerTyping && !_isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTypingIndicator(auraGradient),
              ),

            // Khung trả lời tin nhắn (Reply preview banner)
            if (_replyingMessage != null && !_isMultiSelectMode)
              _buildReplyPreviewBanner(),

            // Thanh chip câu hỏi gợi ý mở lời (Icebreakers)
            if (_messages.length <= 4 && !_isMultiSelectMode)
              _buildIcebreakerChips(),

            // Thanh công cụ nhập liệu đa năng phong cách Telegram / Messenger & Bảng Emoji inline phía dưới
            if (!_isMultiSelectMode) ...[
              _buildTelegramMessengerInputBar(),
              if (_isEmojiPickerVisible)
                CosmicEmojiPickerPanel(
                  onEmojiSelected: _insertEmoji,
                  onBackspace: _handleEmojiBackspace,
                  onClose: () => setState(() => _isEmojiPickerVisible = false),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// AppBar Chế độ Multi-select (Chọn nhiều tin nhắn để xóa/thu hồi)
  PreferredSizeWidget _buildMultiSelectAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
        onPressed: () {
          setState(() {
            _isMultiSelectMode = false;
            _selectedMessageIds.clear();
          });
        },
      ),
      title: Text(
        'Đã chọn ${_selectedMessageIds.length} tin nhắn',
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      actions: [
        if (_selectedMessageIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Xóa hoặc thu hồi',
            onPressed: () {
              _showMultiDeleteConfirmDialog();
            },
          ),
      ],
    );
  }

  void _showMultiDeleteConfirmDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xóa ${_selectedMessageIds.length} tin nhắn đã chọn?',
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('Xóa ở phía tôi', style: TextStyle(fontFamily: 'BeVietnamPro', fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteMultipleMessages(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.undo_rounded, color: Color(0xFF8B5CF6)),
                title: const Text('Thu hồi các tin nhắn của tôi', style: TextStyle(fontFamily: 'BeVietnamPro', fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteMultipleMessages(true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AppBar chuẩn (ĐÃ BỎ TÍCH XANH CẠNH TÊN)
  PreferredSizeWidget _buildStandardAppBar(LinearGradient auraGradient) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(66),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              border: const Border(
                bottom: BorderSide(
                  color: Color(0xFFF1E5ED),
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    // Nút Back
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Nhấn vào Avatar hoặc Tên để xem Profile đối phương
                    Expanded(
                      child: GestureDetector(
                        onTap: _navigateToProfile,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: auraGradient,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: ClipOval(
                                    child: _buildPartnerAvatarImage(),
                                  ),
                                ),
                                // Trạng thái Online
                                Positioned(
                                  right: 0,
                                  bottom: 0,
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

                            // Tên đối phương (ĐÃ BỎ TÍCH XANH)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
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

                    // Nút Gọi thoại trực tiếp (chỉ icon điện thoại thuần túy, không viền tròn)
                    IconButton(
                      tooltip: 'Cuộc gọi thoại',
                      icon: const Icon(
                        Icons.phone_rounded,
                        color: Color(0xFF7C3AED),
                        size: 22,
                      ),
                      onPressed: _handleStartVoiceCall,
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

  /// Khung trích dẫn trả lời (Reply Preview Banner)
  Widget _buildReplyPreviewBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF8B5CF6), width: 3.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: Color(0xFF8B5CF6), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đang trả lời ${_replyingMessage!.isSentByMe ? 'chính bạn' : _partnerDisplayName}',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
            onPressed: () => setState(() => _replyingMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Header Se Duyên (ĐÃ BỎ TÍCH XANH CẠNH TÊN)
  Widget _buildSoulmateConnectionHeader(LinearGradient auraGradient) {
    return GestureDetector(
      onTap: _navigateToProfile,
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFF1E5ED),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar lớn
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: auraGradient,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: _buildPartnerAvatarImage(),
              ),
            ),
            const SizedBox(height: 12),

            // Tên thật đối phương (ĐÃ BỎ TÍCH XANH)
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
                border: Border.all(color: const Color(0xFFDDD6FE)),
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
                border: Border.all(color: const Color(0xFFE0E7FF)),
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

    final effectiveBottomPadding = _isEmojiPickerVisible
        ? 6.0
        : (bottomInset > 0
            ? 6.0
            : (safeBottom > 0 ? safeBottom : 8.0));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
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
          child: _isRecordingVoice
              ? TelegramVoiceRecorderBar(
                  onRecordComplete: _handleVoiceRecordComplete,
                  onRecordCancel: () {
                    setState(() => _isRecordingVoice = false);
                  },
                )
              : Row(
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
                      onPressed: _handlePickCamera,
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
                            // Icon Faye AI gợi ý trả lời (đặt cạnh icon emoji, chỉ icon thuần túy)
                            GestureDetector(
                              onTap: _showAiSuggestionModal,
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 21,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            // Icon Emoji chuyển đổi giữa Bàn phím & Bảng chọn Emoji inline
                            GestureDetector(
                              onTap: _toggleEmojiPicker,
                              child: Icon(
                                _isEmojiPickerVisible
                                    ? Icons.keyboard_alt_outlined
                                    : Icons.sentiment_satisfied_alt_rounded,
                                color: const Color(0xFF7C3AED),
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
                    //    - Rỗng: Nút MICRO ghi âm thoại Telegram (chạm/giữ để ghi)
                    GestureDetector(
                      onTap: () {
                        if (_hasInputText) {
                          _handleSendMessage(_chatController.text);
                        } else {
                          if (CallManager.instance.isInCall) {
                            ToastUtil.showInfo(context, 'Không thể ghi âm khi đang trong cuộc gọi');
                            return;
                          }
                          setState(() => _isRecordingVoice = true);
                        }
                      },
                      onLongPress: () {
                        if (!_hasInputText) {
                          if (CallManager.instance.isInCall) {
                            ToastUtil.showInfo(context, 'Không thể ghi âm khi đang trong cuộc gọi');
                            return;
                          }
                          setState(() => _isRecordingVoice = true);
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

  /// Wrapper cho tin nhắn có checkbox khi ở chế độ Multi-select
  Widget _buildSelectableMessageBubble(ChatMessage msg, LinearGradient auraGradient) {
    final isSelected = _selectedMessageIds.contains(msg.id);

    return GestureDetector(
      onLongPress: () => _showMessageActionMenu(msg),
      onTap: _isMultiSelectMode
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedMessageIds.remove(msg.id);
                } else {
                  _selectedMessageIds.add(msg.id);
                }
              });
            }
          : null,
      child: Container(
        color: isSelected ? const Color(0xFFEDE9FE).withValues(alpha: 0.5) : Colors.transparent,
        child: Row(
          children: [
            if (_isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
            Expanded(
              child: _buildMessageBubble(msg, auraGradient),
            ),
          ],
        ),
      ),
    );
  }

  /// Bong bóng tin nhắn thông minh (Văn bản, Card Stack nhiều ảnh, Ghi âm thoại, Vị trí, Thu hồi)
  Widget _buildMessageBubble(ChatMessage msg, LinearGradient auraGradient) {
    final isMe = msg.isSentByMe;
    final timeString =
        "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";

    final isImageStack = msg.messageType == 'imageStack' || msg.imageUrls.length > 1;
    final isSingleImage = msg.messageType == 'image' || (msg.imageUrls.length == 1) || msg.text.startsWith('[Hình ảnh]');
    final isVoice = msg.isVoice;
    final isLocation = msg.messageType == 'location' || msg.text.startsWith('📍 [Vị trí]');
    final isRevoked = msg.isRevoked;

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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.74,
                    ),
                    padding: (isImageStack || isSingleImage)
                        ? const EdgeInsets.all(4)
                        : (isVoice
                            ? const EdgeInsets.symmetric(vertical: 4, horizontal: 8)
                            : const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                    decoration: BoxDecoration(
                      gradient: isMe && !isRevoked
                          ? const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isRevoked
                          ? const Color(0xFFF1F5F9)
                          : (isMe ? null : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft: isMe ? const Radius.circular(22) : const Radius.circular(6),
                        bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(22),
                      ),
                      border: (isMe && !isRevoked)
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: isMe && !isRevoked
                              ? const Color(0xFFEC4899).withValues(alpha: 0.25)
                              : const Color(0xFF64748B).withValues(alpha: 0.08),
                          blurRadius: isMe ? 12 : 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // Trích dẫn Reply
                        if (msg.replyToText != null && !isRevoked)
                          _buildReplyQuoteBox(msg, isMe),

                        // Nội dung chính
                        _buildBubbleContent(
                          msg,
                          isMe,
                          isSingleImage,
                          isImageStack,
                          isVoice,
                          isLocation,
                          isRevoked,
                        ),
                      ],
                    ),
                  ),

                  // Badge Reaction nổi ở góc dưới bong bóng (❤️, 🔥, 👍,...)
                  if (msg.reaction != null && !isRevoked)
                    Positioned(
                      bottom: -8,
                      right: isMe ? null : -4,
                      left: isMe ? -4 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg.reaction!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

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
                      if (msg.isSending)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                          ),
                        )
                      else if (msg.isSendError)
                        GestureDetector(
                          onTap: () => _retrySendMessage(msg),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.error_outline_rounded, color: Color(0xFFFF3B30), size: 13),
                              SizedBox(width: 2),
                              Text(
                                'Thử lại',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  color: Color(0xFFFF3B30),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
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

  /// Khung trích dẫn Reply bên trong Bubble
  Widget _buildReplyQuoteBox(ChatMessage msg, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : const Color(0xFF8B5CF6),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.replyToSender ?? 'Tin nhắn',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isMe ? Colors.white : const Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            msg.replyToText ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              color: isMe ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng nội dung chi tiết bên trong bong bóng tin nhắn
  Widget _buildBubbleContent(
    ChatMessage msg,
    bool isMe,
    bool isSingleImage,
    bool isImageStack,
    bool isVoice,
    bool isLocation,
    bool isRevoked,
  ) {
    // 1. Trạng thái đã thu hồi
    if (isRevoked) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_flipped, color: Color(0xFF94A3B8), size: 16),
          SizedBox(width: 6),
          Text(
            'Tin nhắn đã được thu hồi',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // 2. Vấn đề 2 & 4.1: Render Modern Glassmorphic Card Stack UI cho nhiều ảnh
    if (isImageStack) {
      return Stack(
        alignment: Alignment.center,
        children: [
          GlassmorphicCardStack(
            images: msg.imageUrls,
            isSentByMe: isMe,
          ),
          if (msg.isSending) _buildImageLoadingOverlay(),
          if (msg.isSendError)
            _buildImageErrorOverlay(() => _retrySendImageMessage(msg)),
        ],
      );
    }

    // 3. Render 1 ảnh đơn lẻ
    if (isSingleImage) {
      final img = msg.imageUrls.isNotEmpty
          ? msg.imageUrls.first
          : msg.text.replaceFirst('[Hình ảnh]', '').trim();

      return Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (msg.isSendError) {
                _retrySendImageMessage(msg);
              } else if (!msg.isSending) {
                GlassmorphicImageViewer.show(context, images: [img], initialIndex: 0);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: img.startsWith('file://')
                  ? Image.file(
                      File(img.replaceFirst('file://', '')),
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildImageError(),
                    )
                  : Image.network(
                      img,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildImageError(),
                    ),
            ),
          ),
          if (msg.isSending) _buildImageLoadingOverlay(),
          if (msg.isSendError)
            _buildImageErrorOverlay(() => _retrySendImageMessage(msg)),
        ],
      );
    }

    // 4. Render Tin nhắn thoại (Voice Note) - Chuẩn Telegram, sóng âm tĩnh tô tiến trình, không rung lắc
    if (isVoice) {
      return CosmicVoicePlayerBubble(
        message: msg,
        isSentByMe: isMe,
        onRetrySend: msg.isSendError ? () => _retrySendVoiceMessage(msg) : null,
      );
    }

    // 5. Render Vị trí (Location Card)
    if (isLocation) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFD1FAE5),
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

    // 6. Văn bản thông thường
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

  Widget _buildImageLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorOverlay(VoidCallback onRetry) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onRetry,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chạm để thử lại',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Typing indicator
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

  /// Ảnh đại diện thật đối phương
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
