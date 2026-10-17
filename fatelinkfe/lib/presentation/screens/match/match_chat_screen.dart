import 'dart:async';
import 'dart:convert';
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
import '../../../services/api_service.dart';
import '../../../services/badge_service.dart';
import '../../../services/app_socket_service.dart';
import '../../../services/call_manager.dart';

// Components & Widgets tách rời sạch sẽ
import '../../widgets/cosmic_report_modal.dart';
import '../profile/user_detail_screen.dart';
import 'widgets/cosmic_location_modal.dart';
import 'widgets/match_ai_suggestion_sheet.dart';
import 'widgets/match_options_bottom_sheet.dart';
import 'widgets/cosmic_emoji_picker_sheet.dart';
import 'widgets/meyufeel_resonance_bar.dart';
import 'widgets/meyufeel_watermark_lotus.dart';
import 'widgets/match_chat_app_bar.dart';
import 'widgets/match_connection_header.dart';
import 'widgets/match_icebreaker_chips.dart';
import 'widgets/match_scroll_bottom_button.dart';
import 'widgets/match_typing_indicator.dart';
import 'widgets/match_telegram_input_bar.dart';
import 'widgets/match_message_bubble.dart';
import 'widgets/match_media_sheet.dart';
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
        final senderId = data['senderId']?.toString() ?? '';
        final partnerId = data['partnerId']?.toString() ?? '';
        final isForThisChat = senderId == widget.partnerId || partnerId == widget.partnerId;

        if (isForThisChat) {
          HapticFeedback.lightImpact();
          final bool isSentByMe = data['isSentByMe'] == true || (senderId.isNotEmpty && senderId != widget.partnerId);
          final map = Map<String, dynamic>.from(data);
          map['isSentByMe'] = isSentByMe;
          final chatMsg = ChatMessage.fromJson(map);

          debugPrint(
            '📩 [Socket Receive] Tin nhắn phòng chat: id=${chatMsg.id}, isSentByMe=$isSentByMe, text=${chatMsg.text.length > 30 ? chatMsg.text.substring(0, 30) : chatMsg.text}',
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
    MatchMediaSheet.show(
      context,
      onPickMultiImages: _handlePickMultiImages,
      onPickCamera: _handlePickCamera,
      onShareLocation: _handleShareLocation,
      onVoiceNote: _handleVoiceNote,
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

    final partnerAvatarWidget = _buildPartnerAvatarImage();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MatchChatAppBar(
        isMultiSelectMode: _isMultiSelectMode,
        selectedCount: _selectedMessageIds.length,
        onCloseMultiSelect: () {
          setState(() {
            _isMultiSelectMode = false;
            _selectedMessageIds.clear();
          });
        },
        onDeleteSelected: _showMultiDeleteConfirmDialog,
        partnerDisplayName: _partnerDisplayName,
        partnerAvatarWidget: partnerAvatarWidget,
        partnerHertz: _partnerHertz ?? '528 Hz',
        isPartnerOnline: _isPartnerOnline,
        onBack: () => Navigator.pop(context),
        onPartnerProfileTap: _navigateToProfile,
        onStartVoiceCall: _handleStartVoiceCall,
        onOptionsTap: _showOptionsModal,
      ),
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
                                return MatchConnectionHeader(
                                  auraGradient: auraGradient,
                                  partnerAvatarWidget: partnerAvatarWidget,
                                  partnerDisplayName: _partnerDisplayName,
                                  partnerHertz: _partnerHertz ?? '528 Hz',
                                  partnerBio: _partnerBio,
                                  onProfileTap: _navigateToProfile,
                                );
                              }
                              final msg = _messages[index];
                              final isSelected = _selectedMessageIds.contains(msg.id);

                              return MatchMessageBubble(
                                message: msg,
                                isMultiSelectMode: _isMultiSelectMode,
                                isSelected: isSelected,
                                auraGradient: auraGradient,
                                partnerAvatarWidget: partnerAvatarWidget,
                                onPartnerProfileTap: _navigateToProfile,
                                onLongPress: () => _showMessageActionMenu(msg),
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedMessageIds.remove(msg.id);
                                    } else {
                                      _selectedMessageIds.add(msg.id);
                                    }
                                  });
                                },
                                onRetrySendMessage: _retrySendMessage,
                                onRetrySendImageMessage: _retrySendImageMessage,
                                onRetrySendVoiceMessage: _retrySendVoiceMessage,
                                onStartVoiceCall: _handleStartVoiceCall,
                              );
                            },
                          ),
                  ),
                  // Nút mũi tên cuộn xuống tin nhắn mới nhất
                  MatchScrollBottomButton(
                    isVisible: !_isNearBottom,
                    unreadCount: _unreadCount,
                    onTap: () {
                      _scrollToBottom();
                      if (_unreadCount > 0) {
                        setState(() => _unreadCount = 0);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Đang nhập văn bản (Typing indicator)
            if (_isPartnerTyping && !_isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MatchTypingIndicator(
                  auraGradient: auraGradient,
                  partnerAvatarWidget: partnerAvatarWidget,
                ),
              ),

            // Thanh chip câu hỏi gợi ý mở lời (Icebreakers)
            if (_messages.length <= 4 && !_isMultiSelectMode)
              MatchIcebreakerChips(
                icebreakers: _icebreakers,
                onSelectPrompt: _handleSendMessage,
              ),

            // Thanh công cụ nhập liệu đa năng phong cách Telegram & Bảng Emoji inline phía dưới
            if (!_isMultiSelectMode) ...[
              MatchTelegramInputBar(
                chatController: _chatController,
                focusNode: _focusNode,
                hasInputText: _hasInputText,
                isRecordingVoice: _isRecordingVoice,
                isEmojiPickerVisible: _isEmojiPickerVisible,
                partnerDisplayName: _partnerDisplayName,
                replyingMessage: _replyingMessage,
                onCancelReply: () => setState(() => _replyingMessage = null),
                onShowMediaActionSheet: _showMediaActionSheet,
                onPickCamera: _handlePickCamera,
                onShowAiSuggestionModal: _showAiSuggestionModal,
                onToggleEmojiPicker: _toggleEmojiPicker,
                onSendMessage: _handleSendMessage,
                onStartRecordVoice: () {
                  if (CallManager.instance.isInCall) {
                    ToastUtil.showInfo(context, 'Không thể ghi âm khi đang trong cuộc gọi');
                    return;
                  }
                  setState(() => _isRecordingVoice = true);
                },
                onCancelRecordVoice: () {
                  setState(() => _isRecordingVoice = false);
                },
                onVoiceRecordComplete: _handleVoiceRecordComplete,
              ),
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
