import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/utils/constants.dart';
import '../core/utils/secure_storage_helper.dart';
import 'api_service.dart';
import 'badge_service.dart';
import 'call_manager.dart';

/// Dịch vụ Socket.IO toàn cục cho FateLink
/// - Kết nối WebRTC & Direct Message xuyên suốt vòng đời ứng dụng
/// - Ép buộc transport CHỈ 'websocket' (không dùng polling gây lỗi session)
/// - Quản lý gửi tin nhắn có Ack Callback & Timeout 8s + Auto Retry
/// - Lắng nghe tin nhắn toàn app để cập nhật badge số đếm và thông báo
class AppSocketService {
  static final AppSocketService _instance = AppSocketService._internal();
  factory AppSocketService() => _instance;
  static AppSocketService get instance => _instance;
  AppSocketService._internal();

  IO.Socket? _socket;
  String? _currentToken;
  String? _activeChatPartnerId; // ID của đối tác đang mở màn hình chat (để không tăng unread badge)

  // Stream Controllers cho các sự kiện toàn app
  final _directMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _incomingCallController = StreamController<Map<String, dynamic>>.broadcast();
  final _userStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectController = StreamController<void>.broadcast();

  // ValueNotifiers cho UI phản ứng nhanh
  final ValueNotifier<int> totalUnreadCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  // Getters
  IO.Socket? get socket => _socket;
  Stream<Map<String, dynamic>> get directMessageStream => _directMessageController.stream;
  Stream<Map<String, dynamic>> get messageStream => _directMessageController.stream;
  Stream<Map<String, dynamic>> get incomingCallStream => _incomingCallController.stream;
  Stream<Map<String, dynamic>> get userStatusStream => _userStatusController.stream;
  Stream<void> get reconnectStream => _reconnectController.stream;

  /// Đánh dấu màn hình chat đang mở với một partnerId cụ thể
  void setActiveChatPartner(String? partnerId) {
    _activeChatPartnerId = partnerId;
  }

  /// Khởi tạo và kết nối Socket toàn app
  Future<void> initialize() async {
    try {
      var token = await SecureStorageHelper.read('accessToken');
      if (token == null || token.isEmpty) return;

      final cleanToken = token.replaceFirst(RegExp(r'^Bearer\s+'), '').trim();
      connect(cleanToken);
    } catch (e) {
      debugPrint('⚠️ [AppSocketService] Lỗi đọc token khi khởi tạo: $e');
    }
  }

  /// Kết nối tới WebSocket Gateway của FateLink
  void connect(String token) {
    if (_socket != null && _socket!.connected && _currentToken == token) {
      return;
    }

    _currentToken = token;
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    debugPrint('🌐 [AppSocketService] Bắt đầu kết nối Socket.IO: ${AppConstants.serverUrl} (chỉ websocket)');

    _socket = IO.io(
      AppConstants.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Bắt buộc CHỈ websocket, không dùng polling
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _registerSocketListeners();
    CallManager.instance.bindSocket(_socket!);
    _socket!.connect();
  }

  void _registerSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      isConnected.value = true;
      debugPrint('✅ [AppSocketService] Đã kết nối Socket.IO thành công (Socket ID: ${_socket!.id})');
      _reconnectController.add(null);
    });

    _socket!.onDisconnect((_) {
      isConnected.value = false;
      debugPrint('❌ [AppSocketService] Socket.IO ngắt kết nối');
    });

    _socket!.onConnectError((err) {
      isConnected.value = false;
      debugPrint('⚠️ [AppSocketService] Lỗi kết nối Socket.IO: $err');
    });

    _socket!.onError((err) {
      debugPrint('⚠️ [AppSocketService] Socket.IO gặp lỗi: $err');
    });

    // Lắng nghe tin nhắn trực tiếp 1-1 toàn app
    _socket!.on('receiveDirectMessage', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final senderId = map['senderId']?.toString() ?? '';
        final msgId = map['id']?.toString() ?? '';
        final msgType = map['messageType']?.toString() ?? 'text';

        debugPrint(
          '📩 [Socket Receive] Bên nhận: receiveDirectMessage: id=$msgId, senderId=$senderId, type=$msgType',
        );

        // Phát ra stream toàn app
        _directMessageController.add(map);

        // Nếu người dùng KHÔNG đang ở trong phòng chat với sender này -> tăng unread badge
        if (_activeChatPartnerId != senderId) {
          totalUnreadCount.value += 1;
          BadgeService.increment();
        }
      }
    });

    // Lắng nghe cuộc gọi thoại tới toàn app
    _socket!.on('incomingVoiceCall', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        debugPrint('📞 [Socket Call] Nhận cuộc gọi thoại tới: $map');
        _incomingCallController.add(map);
      }
    });

    // Lắng nghe trạng thái online/offline của người dùng
    _socket!.on('userStatusChanged', (data) {
      if (data is Map) {
        _userStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    // Token hết hạn -> Tự động làm mới và kết nối lại
    _socket!.on('authError', (data) async {
      debugPrint('⚠️ [AppSocketService] Nhận authError từ server, thử refresh token...');
      final newToken = await ApiService.tryRefreshToken();
      if (newToken != null && newToken.isNotEmpty) {
        final clean = newToken.replaceFirst(RegExp(r'^Bearer\s+'), '').trim();
        connect(clean);
      }
    });
  }

  /// Gửi tin nhắn trực tiếp với Ack Callback + Timeout 8s + Tự động thử lại
  /// Trả về Map ack từ server nếu thành công: { 'success': true, 'id': ..., 'clientMessageId': ..., 'timestamp': ... }
  /// Throw Exception nếu thất bại hoặc timeout quá thời gian
  Future<Map<String, dynamic>> sendDirectMessageWithAck({
    required String partnerId,
    required String text,
    String? messageType,
    String? mediaUrl,
    int? durationMs,
    List<int>? waveform,
    List<String>? imageUrls,
    required String clientMessageId,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket chưa kết nối, không thể gửi tin nhắn.');
    }

    final payload = {
      'partnerId': partnerId,
      'text': text,
      'messageType': messageType ?? 'text',
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (durationMs != null) 'durationMs': durationMs,
      if (waveform != null) 'waveform': waveform,
      if (imageUrls != null) 'imageUrls': imageUrls,
      'clientMessageId': clientMessageId,
    };

    debugPrint(
      '🚀 [Socket Send] emit sendDirectMessage: partnerId=$partnerId, clientMsgId=$clientMessageId, type=${payload['messageType']}',
    );

    // Lần thử 1
    try {
      final ack = await _emitWithTimeout(payload, timeout: const Duration(seconds: 8));
      return ack;
    } catch (e) {
      debugPrint('⚠️ [Socket Send] Lần 1 timeout/lỗi ($e), tự động thử lại lần 2 cùng clientMessageId: $clientMessageId');
      // Thử lại lần 2 (cùng clientMessageId để backend chống trùng lặp)
      final ackRetry = await _emitWithTimeout(payload, timeout: const Duration(seconds: 8));
      return ackRetry;
    }
  }

  /// Đẩy tin nhắn trực tiếp cục bộ vào stream (dùng cho các tin nhắn do chính mình tạo ra như cuộc gọi thoại)
  void emitLocalDirectMessage(Map<String, dynamic> messagePayload) {
    _directMessageController.add(messagePayload);
  }

  Future<Map<String, dynamic>> _emitWithTimeout(
    Map<String, dynamic> payload, {
    required Duration timeout,
  }) {
    final completer = Completer<Map<String, dynamic>>();
    Timer? timer;

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Quá thời gian chờ ack (${timeout.inSeconds}s) từ server'),
        );
      }
    });

    _socket!.emitWithAck(
      'sendDirectMessage',
      payload,
      ack: (response) {
        timer?.cancel();
        if (completer.isCompleted) return;

        if (response is Map) {
          final resMap = Map<String, dynamic>.from(response);
          debugPrint(
            '📥 [Socket Ack] Nhận được ack từ server: id=${resMap['id']}, clientMsgId=${resMap['clientMessageId']}, success=${resMap['success']}',
          );
          if (resMap['success'] == true) {
            completer.complete(resMap);
          } else {
            completer.completeError(
              Exception(resMap['error']?.toString() ?? 'Gửi tin nhắn thất bại'),
            );
          }
        } else {
          debugPrint('📥 [Socket Ack] Nhận ack raw từ server: $response');
          completer.complete({'success': true, 'raw': response});
        }
      },
    );

    return completer.future;
  }

  /// Ngắt kết nối và giải phóng tài nguyên
  void dispose() {
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
  }
}
