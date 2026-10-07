import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/router/app_router.dart';
import '../core/services/webrtc_voice_call_service.dart';
import '../core/utils/toast_utils.dart';
import '../presentation/screens/call/cosmic_voice_call_screen.dart';
import 'app_socket_service.dart';

/// Máy trạng thái vòng đời cuộc gọi
enum CallState {
  idle,             // Không có cuộc gọi
  outgoingRinging,  // Cuộc gọi đi: đang đổ chuông chờ đối phương
  incomingRinging,  // Cuộc gọi đến: đang reo chuông chờ người dùng nhận
  connecting,       // Đang thiết lập WebRTC P2P (chưa có audio stream)
  connected,        // Đã kết nối WebRTC thành công (đang đàm thoại)
  ended,            // Cuộc gọi kết thúc
}

/// Thông tin phiên cuộc gọi
class CallSession {
  final String callId;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatar;
  final bool isCaller;
  final dynamic offerSdp;
  DateTime? connectedAt;

  CallSession({
    required this.callId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
    required this.isCaller,
    this.offerSdp,
    this.connectedAt,
  });

  CallSession copyWith({
    String? callId,
    String? partnerId,
    String? partnerName,
    String? partnerAvatar,
    bool? isCaller,
    dynamic offerSdp,
    DateTime? connectedAt,
  }) {
    return CallSession(
      callId: callId ?? this.callId,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      isCaller: isCaller ?? this.isCaller,
      offerSdp: offerSdp ?? this.offerSdp,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

/// CallManager (Singleton toàn app)
/// - Quản lý máy trạng thái cuộc gọi
/// - Điều phối âm thanh nhạc chuông / ringback / rung
/// - Quản lý duy nhất việc push / pop route cuộc gọi bằng AppRouter.navigatorKey
/// - Giữ callId cho mọi sự kiện signaling
class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  static CallManager get instance => _instance;

  CallManager._internal() {
    _subscribeWebRtcEvents();
  }

  IO.Socket? _socket;
  CallSession? _currentSession;

  // Notifiers phục vụ UI phản ứng mượt mà
  final ValueNotifier<CallState> stateNotifier = ValueNotifier<CallState>(CallState.idle);
  final ValueNotifier<int> durationSecondsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isMutedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSpeakerOnNotifier = ValueNotifier<bool>(false);

  CallState get state => stateNotifier.value;
  CallSession? get currentSession => _currentSession;
  bool get isInCall => state != CallState.idle && state != CallState.ended;

  // Quản lý âm thanh chuông / rung / timeout
  AudioPlayer? _audioPlayer;
  Timer? _vibrationTimer;
  Timer? _ringingTimeoutTimer;
  Timer? _callDurationTimer;

  bool _isScreenPushed = false;
  StreamSubscription? _rtcConnSub;
  StreamSubscription? _rtcIceSub;

  /// Đăng ký lắng nghe sự kiện từ WebRtcVoiceCallService
  void _subscribeWebRtcEvents() {
    _rtcConnSub = WebRtcVoiceCallService.instance.onConnectionStateChanged.listen((rtcState) {
      debugPrint('🛰️ [CallManager] WebRTC ConnectionState: $rtcState');

      if (rtcState.toString().contains('Connected')) {
        _onCallConnected();
      } else if (rtcState.toString().contains('Failed') || rtcState.toString().contains('Closed')) {
        if (state == CallState.connected || state == CallState.connecting) {
          debugPrint('⚠️ [CallManager] WebRTC bị ngắt kết nối (State: $rtcState)');
          _notifyAndEnd(reason: 'Mất kết nối cuộc gọi');
        }
      }
    });

    _rtcIceSub = WebRtcVoiceCallService.instance.onIceConnectionStateChanged.listen((iceState) {
      debugPrint('❄️ [CallManager] WebRTC IceConnectionState: $iceState');
      if (iceState.toString().contains('Connected') || iceState.toString().contains('Completed')) {
        _onCallConnected();
      }
    });
  }

  void _onCallConnected() {
    if (state != CallState.connected) {
      debugPrint('🎉 [CallManager] Kênh âm thanh P2P đã thông suốt! Bắt đầu đếm giây.');
      _stopSounds();
      _ringingTimeoutTimer?.cancel();
      _currentSession?.connectedAt = DateTime.now();
      stateNotifier.value = CallState.connected;
      _startDurationTimer();
      HapticFeedback.mediumImpact();
    }
  }

  /// Gắn Socket.IO toàn cục để quản lý signaling xuyên suốt vòng đời app
  void bindSocket(IO.Socket socket) {
    if (_socket == socket) return;
    _unbindSocket();

    _socket = socket;
    debugPrint('🔌 [CallManager] Gắn kết nối Socket.IO toàn cục');

    _socket!.on('incomingVoiceCall', _onIncomingVoiceCall);
    _socket!.on('voiceCallRinging', _onVoiceCallRinging);
    _socket!.on('voiceCallAccepted', _onVoiceCallAccepted);
    _socket!.on('voiceCallRejected', _onVoiceCallRejected);
    _socket!.on('voiceCallEnded', _onVoiceCallEnded);
    _socket!.on('voiceCallBusy', _onVoiceCallBusy);
    _socket!.on('voiceCallMissed', _onVoiceCallMissed);
    _socket!.on('voiceCallAnsweredElsewhere', _onVoiceCallAnsweredElsewhere);
    _socket!.on('webrtcAnswer', _onWebRtcAnswer);
    _socket!.on('iceCandidate', _onIceCandidate);
  }

  void _unbindSocket() {
    if (_socket == null) return;
    _socket!.off('incomingVoiceCall', _onIncomingVoiceCall);
    _socket!.off('voiceCallRinging', _onVoiceCallRinging);
    _socket!.off('voiceCallAccepted', _onVoiceCallAccepted);
    _socket!.off('voiceCallRejected', _onVoiceCallRejected);
    _socket!.off('voiceCallEnded', _onVoiceCallEnded);
    _socket!.off('voiceCallBusy', _onVoiceCallBusy);
    _socket!.off('voiceCallMissed', _onVoiceCallMissed);
    _socket!.off('voiceCallAnsweredElsewhere', _onVoiceCallAnsweredElsewhere);
    _socket!.off('webrtcAnswer', _onWebRtcAnswer);
    _socket!.off('iceCandidate', _onIceCandidate);
    _socket = null;
  }

  // ==========================================
  // --- SIGNALLING EVENT HANDLERS ---
  // ==========================================

  void _onIncomingVoiceCall(dynamic data) {
    debugPrint('📞 [CallManager] Nhận sự kiện incomingVoiceCall: $data');
    if (data is! Map) return;

    final callId = data['callId']?.toString() ?? '';
    final callerId = data['callerId']?.toString() ?? '';
    final callerName = data['callerName']?.toString() ?? 'Bạn tâm giao';
    final callerAvatar = data['callerAvatar']?.toString();
    final sdp = data['sdp'];

    // Nếu đang trong cuộc gọi khác -> Báo bận
    if (isInCall) {
      debugPrint('⚠️ [CallManager] Đang trong cuộc gọi khác, từ chối nhận cuộc gọi mới: $callId');
      _socket?.emit('rejectVoiceCall', {
        'callId': callId,
        'callerId': callerId,
        'reason': 'busy',
      });
      return;
    }

    _currentSession = CallSession(
      callId: callId,
      partnerId: callerId,
      partnerName: callerName,
      partnerAvatar: callerAvatar,
      isCaller: false,
      offerSdp: sdp,
    );

    durationSecondsNotifier.value = 0;
    isMutedNotifier.value = false;
    isSpeakerOnNotifier.value = false;
    stateNotifier.value = CallState.incomingRinging;

    _playRingtone();
    _start30sTimeout();
    _openCallScreen();
  }

  void _onVoiceCallRinging(dynamic data) {
    debugPrint('🔔 [CallManager] Máy đối phương đang đổ chuông: $data');
    if (data is Map && data['callId'] != null && _currentSession != null) {
      _currentSession = _currentSession!.copyWith(callId: data['callId'].toString());
    }
  }

  void _onVoiceCallAccepted(dynamic data) {
    debugPrint('✅ [CallManager] Đối phương đã nhấc máy: $data');
    if (!isInCall) return;

    _stopSounds();
    _ringingTimeoutTimer?.cancel();
    stateNotifier.value = CallState.connecting;
  }

  void _onVoiceCallRejected(dynamic data) {
    debugPrint('❌ [CallManager] Đối phương từ chối cuộc gọi: $data');
    final session = _currentSession;
    if (session != null && session.isCaller) {
      _recordCallMessageToChat(
        partnerId: session.partnerId,
        text: 'Cuộc gọi thoại bị từ chối',
        messageType: 'call_rejected',
        clientMessageId: 'call_rej_${session.callId}',
      );
    }
    _notifyAndEnd(reason: 'Đối phương đã từ chối cuộc gọi');
  }

  void _onVoiceCallEnded(dynamic data) {
    debugPrint('🛑 [CallManager] Nhận sự kiện voiceCallEnded: $data');
    _notifyAndEnd(reason: 'Cuộc gọi thoại đã kết thúc');
  }

  void _onVoiceCallBusy(dynamic data) {
    debugPrint('⏳ [CallManager] Đối phương đang bận cuộc gọi khác: $data');
    _notifyAndEnd(reason: 'Người dùng hiện đang bận cuộc gọi khác');
  }

  void _onVoiceCallMissed(dynamic data) {
    debugPrint('⏱️ [CallManager] Cuộc gọi nhỡ hoặc hết thời gian chờ: $data');
    final session = _currentSession;
    if (session != null && session.isCaller) {
      _recordCallMessageToChat(
        partnerId: session.partnerId,
        text: 'Cuộc gọi thoại nhỡ',
        messageType: 'call_missed',
        clientMessageId: 'call_mis_${session.callId}',
      );
    }
    _notifyAndEnd(reason: 'Cuộc gọi nhỡ / Không trả lời');
  }

  void _onVoiceCallAnsweredElsewhere(dynamic data) {
    debugPrint('📱 [CallManager] Cuộc gọi đã được trả lời trên thiết bị khác: $data');
    _stopSounds();
    _cleanup(notifyPeer: false);
    _closeCallScreen();
  }

  void _onWebRtcAnswer(dynamic data) {
    debugPrint('📥 [CallManager] Nhận webrtcAnswer từ đối phương');
    if (data is Map && data['sdp'] != null) {
      WebRtcVoiceCallService.instance.handleRemoteAnswer(data['sdp']);
    }
  }

  void _onIceCandidate(dynamic data) {
    if (data is Map && data['candidate'] != null) {
      WebRtcVoiceCallService.instance.handleRemoteCandidate(data['candidate']);
    }
  }

  // ==========================================
  // --- USER ACTIONS ---
  // ==========================================

  /// Bắt đầu cuộc gọi đi tới đối phương
  Future<bool> startOutgoingCall({
    required String partnerId,
    required String partnerName,
    String? partnerAvatar,
  }) async {
    if (isInCall) {
      ToastUtil.showInfo(null, 'Bạn đang có một cuộc gọi đang diễn ra');
      return false;
    }

    // 1. Kiểm tra quyền Microphone an toàn (không chặn cứng nếu permission_handler trả về denied trên Simulator)
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        await Permission.microphone.request();
      }
    } catch (e) {
      debugPrint('⚠️ [CallManager] Lỗi kiểm tra mic permission: $e');
    }

    if (_socket == null || !_socket!.connected) {
      ToastUtil.showError(null, 'Chưa kết nối mạng thời gian thực, vui lòng thử lại');
      return false;
    }

    // 2. Tạo phiên cuộc gọi
    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    _currentSession = CallSession(
      callId: callId,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerAvatar: partnerAvatar,
      isCaller: true,
    );

    durationSecondsNotifier.value = 0;
    isMutedNotifier.value = false;
    isSpeakerOnNotifier.value = false;
    stateNotifier.value = CallState.outgoingRinging;

    _playRingback();
    _start30sTimeout();
    _openCallScreen();

    // 3. Khởi tạo WebRTC Caller và gửi SDP Offer kèm theo startVoiceCall
    final offerSdp = await WebRtcVoiceCallService.instance.initiateCall(
      callId: callId,
      partnerId: partnerId,
      onIceCandidateGenerated: (candidate) {
        if (_socket != null && _socket!.connected) {
          _socket!.emit('iceCandidate', {
            'callId': callId,
            'partnerId': partnerId,
            'candidate': candidate.toMap(),
          });
        }
      },
    );

    if (offerSdp == null) {
      _notifyAndEnd(reason: 'Không thể khởi tạo kết nối âm thanh');
      return false;
    }

    // Gộp offer vào lời mời gọi theo chuẩn kiến trúc B2
    _socket!.emit('startVoiceCall', {
      'partnerId': partnerId,
      'sdp': offerSdp,
    });

    return true;
  }

  /// Trả lời cuộc gọi đến
  Future<bool> acceptIncomingCall() async {
    debugPrint('👉 [CallManager] Người dùng bấm acceptIncomingCall()');
    if (_currentSession == null || state != CallState.incomingRinging) return false;

    // Yêu cầu quyền Micro an toàn, không tự động cúp máy / reject nếu permission_handler trả về denied trên Simulator/iOS
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        await Permission.microphone.request();
      }
    } catch (e) {
      debugPrint('⚠️ [CallManager] Lỗi kiểm tra mic permission: $e');
    }

    _stopSounds();
    _ringingTimeoutTimer?.cancel();
    stateNotifier.value = CallState.connecting;

    final callId = _currentSession!.callId;
    final callerId = _currentSession!.partnerId;
    final offerSdp = _currentSession!.offerSdp;

    // Báo server là mình đã chấp nhận
    _socket?.emit('acceptVoiceCall', {
      'callId': callId,
      'callerId': callerId,
    });

    // Khởi tạo WebRTC Receiver và tạo SDP Answer
    final answerSdp = await WebRtcVoiceCallService.instance.answerCall(
      callId: callId,
      callerId: callerId,
      offerSdp: offerSdp,
      onIceCandidateGenerated: (candidate) {
        if (_socket != null && _socket!.connected) {
          _socket!.emit('iceCandidate', {
            'callId': callId,
            'partnerId': callerId,
            'candidate': candidate.toMap(),
          });
        }
      },
    );

    if (answerSdp != null) {
      _socket?.emit('webrtcAnswer', {
        'callId': callId,
        'partnerId': callerId,
        'sdp': answerSdp,
      });
      return true;
    } else {
      _notifyAndEnd(reason: 'Không thể thiết lập âm thanh cuộc gọi');
      return false;
    }
  }

  /// Từ chối cuộc gọi đến
  void rejectIncomingCall({String reason = 'declined'}) {
    if (_currentSession == null) return;
    final callId = _currentSession!.callId;
    final callerId = _currentSession!.partnerId;

    _stopSounds();
    _ringingTimeoutTimer?.cancel();

    _socket?.emit('rejectVoiceCall', {
      'callId': callId,
      'callerId': callerId,
      'reason': reason,
    });

    _cleanup(notifyPeer: false);
    _closeCallScreen();
  }

  /// Chủ động cúp máy kết thúc cuộc gọi
  void hangUp({String reason = 'user_hung_up'}) {
    if (!isInCall) return;

    final partnerId = _currentSession?.partnerId;
    final callId = _currentSession?.callId;

    _stopSounds();
    _ringingTimeoutTimer?.cancel();

    if (_socket != null && _socket!.connected && partnerId != null) {
      _socket!.emit('endVoiceCall', {
        'callId': callId,
        'partnerId': partnerId,
        'reason': reason,
      });
    }

    _cleanup(notifyPeer: false);
    _closeCallScreen();
  }

  /// Bật / Tắt Mic
  void toggleMute() {
    WebRtcVoiceCallService.instance.toggleMute();
    isMutedNotifier.value = WebRtcVoiceCallService.instance.isMuted;
  }

  /// Chuyển đổi Loa Ngoài / Tai Nghe
  Future<void> toggleSpeaker() async {
    final isSpeaker = await WebRtcVoiceCallService.instance.toggleSpeaker();
    isSpeakerOnNotifier.value = isSpeaker;
  }

  // ==========================================
  // --- INTERNAL HELPER LOGIC ---
  // ==========================================

  void _notifyAndEnd({required String reason}) {
    _stopSounds();
    _ringingTimeoutTimer?.cancel();
    _cleanup(notifyPeer: false);
    _closeCallScreen();
    ToastUtil.showInfo(null, reason);
  }

  void _cleanup({required bool notifyPeer}) {
    _stopSounds();
    _ringingTimeoutTimer?.cancel();

    // Ghi nhận tin nhắn kết thúc cuộc gọi nếu cuộc gọi đã được kết nối và bên này là Caller
    final session = _currentSession;
    final duration = durationSecondsNotifier.value;
    if (session != null && session.isCaller && session.connectedAt != null && duration > 0) {
      final durationText = _formatDuration(duration);
      _recordCallMessageToChat(
        partnerId: session.partnerId,
        text: 'Cuộc gọi thoại ($durationText)',
        messageType: 'call_ended',
        durationMs: duration * 1000,
        clientMessageId: 'call_end_${session.callId}',
      );
    }

    _callDurationTimer?.cancel();
    _callDurationTimer = null;

    WebRtcVoiceCallService.instance.endCall(notifyPeer: notifyPeer);

    stateNotifier.value = CallState.ended;
    Future.delayed(const Duration(milliseconds: 300), () {
      stateNotifier.value = CallState.idle;
      _currentSession = null;
    });
  }

  void _startDurationTimer() {
    _callDurationTimer?.cancel();
    durationSecondsNotifier.value = 0;
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      durationSecondsNotifier.value++;
    });
  }

  void _start30sTimeout() {
    _ringingTimeoutTimer?.cancel();
    _ringingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      debugPrint('⏱️ [CallManager] 30 giây không ai nhấc máy');
      final session = _currentSession;
      if (session != null && session.isCaller) {
        _recordCallMessageToChat(
          partnerId: session.partnerId,
          text: 'Cuộc gọi thoại nhỡ',
          messageType: 'call_missed',
          clientMessageId: 'call_mis_${session.callId}',
        );
      }
      _notifyAndEnd(reason: 'Không có phản hồi từ đối phương');
    });
  }

  /// Gửi tin nhắn trạng thái cuộc gọi vào khung chat
  Future<void> _recordCallMessageToChat({
    required String partnerId,
    required String text,
    required String messageType,
    int? durationMs,
    required String clientMessageId,
  }) async {
    try {
      debugPrint('📝 [CallManager] Ghi nhận lịch sử cuộc gọi vào Chat: $text (type=$messageType)');

      // 1. Phát trực tiếp cho UI của chính mình (Caller) thấy ngay tức thì giống Messenger
      AppSocketService.instance.emitLocalDirectMessage({
        'id': clientMessageId,
        'partnerId': partnerId,
        'text': text,
        'messageType': messageType,
        'durationMs': durationMs,
        'clientMessageId': clientMessageId,
        'timestamp': DateTime.now().toIso8601String(),
        'isSentByMe': true,
      });

      // 2. Gửi qua socket Ack tới Server để lưu DB và chuyển tiếp cho Callee
      await AppSocketService.instance.sendDirectMessageWithAck(
        partnerId: partnerId,
        text: text,
        messageType: messageType,
        durationMs: durationMs,
        clientMessageId: clientMessageId,
      );
    } catch (e) {
      debugPrint('⚠️ [CallManager] Không thể lưu tin nhắn cuộc gọi vào Chat: $e');
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _playRingtone() async {
    await _stopSounds();
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.play(AssetSource('sounds/ringtone.wav'));
    } catch (e) {
      debugPrint('⚠️ [CallManager] Lỗi phát ringtone: $e');
    }
    _startVibration();
  }

  Future<void> _playRingback() async {
    await _stopSounds();
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.play(AssetSource('sounds/ringback.wav'));
    } catch (e) {
      debugPrint('⚠️ [CallManager] Lỗi phát ringback: $e');
    }
  }

  Future<void> _stopSounds() async {
    _stopVibration();
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
      } catch (_) {}
      _audioPlayer = null;
    }
  }

  void _startVibration() {
    _stopVibration();
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  void _openCallScreen() {
    if (_isScreenPushed) return;
    _isScreenPushed = true;

    final sessionForThisRoute = _currentSession;
    AppRouter.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const CosmicVoiceCallScreen(),
        settings: const RouteSettings(name: '/voice-call'),
      ),
    ).then((_) {
      _isScreenPushed = false;
      // Chỉ cúp máy nếu phiên cuộc gọi hiện tại vẫn là phiên của route vừa pop
      // Tránh việc route cũ vừa pop xong lại cúp máy phiên cuộc gọi mới!
      if (isInCall && _currentSession == sessionForThisRoute) {
        hangUp();
      }
    });
  }

  void _closeCallScreen() {
    if (_isScreenPushed) {
      _isScreenPushed = false;
      AppRouter.navigatorKey.currentState?.pop();
    }
  }

  void dispose() {
    _unbindSocket();
    _stopSounds();
    _ringingTimeoutTimer?.cancel();
    _callDurationTimer?.cancel();
    _rtcConnSub?.cancel();
    _rtcIceSub?.cancel();
  }
}
