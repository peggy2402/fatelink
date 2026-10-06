import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/api_service.dart';

/// Dịch vụ quản lý kết nối cuộc gọi thoại Real-time qua WebRTC (P2P Audio Stream).
/// - Xử lý ICE Candidate Queue để chống mất candidate trước khi setRemoteDescription.
/// - Trạng thái "connected" CHỈ lấy từ WebRTC ConnectionState thật (connected/completed).
/// - Hỗ trợ ICE restart 1 lần khi kết nối bị đứt.
/// - Âm thanh mặc định ra TAI NGHE (earpiece), có nút chuyển Loa ngoài.
/// - Không tự ý pop route (CallManager chịu trách nhiệm điều phối điều hướng duy nhất).
class WebRtcVoiceCallService {
  static final WebRtcVoiceCallService _instance = WebRtcVoiceCallService._internal();
  factory WebRtcVoiceCallService() => _instance;
  static WebRtcVoiceCallService get instance => _instance;
  WebRtcVoiceCallService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  String? _currentCallId;
  String? _currentPartnerId;
  bool _isCaller = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false; // Mặc định là TAI NGHE (earpiece) theo yêu cầu kiến trúc B2
  bool _hasSetRemoteDescription = false;
  bool _hasAttemptedIceRestart = false;

  // Hàng đợi ICE Candidate cho các candidate đến trước khi RemoteDescription được thiết lập
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  // Stream Controllers để cập nhật trạng thái ra CallManager và UI
  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  final _iceConnectionStateController = StreamController<RTCIceConnectionState>.broadcast();
  final _callEndedController = StreamController<String?>.broadcast();

  Stream<RTCPeerConnectionState> get onConnectionStateChanged => _connectionStateController.stream;
  Stream<RTCIceConnectionState> get onIceConnectionStateChanged => _iceConnectionStateController.stream;
  Stream<String?> get onCallEnded => _callEndedController.stream;

  bool get isCaller => _isCaller;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get currentCallId => _currentCallId;
  String? get currentPartnerId => _currentPartnerId;

  // Cấu hình STUN mặc định làm cứu cánh nếu mạng không lấy được API ICE Servers
  static const Map<String, dynamic> _defaultIceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Lấy cấu hình WebRTC kèm STUN/TURN động từ Backend
  Future<Map<String, dynamic>> _getEffectiveIceConfiguration() async {
    try {
      final servers = await ApiService.getIceServers();
      if (servers != null && servers.isNotEmpty) {
        debugPrint('🌐 [WebRTC] Đã lấy ${servers.length} ICE Servers (STUN/TURN) từ backend');
        return {
          'iceServers': servers,
          'sdpSemantics': 'unified-plan',
        };
      }
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Không thể lấy ICE Servers động, dùng fallback: $e');
    }
    return _defaultIceConfig;
  }

  /// Khởi tạo kết nối cuộc gọi phía Người gọi (Caller)
  Future<Map<String, dynamic>?> initiateCall({
    required String callId,
    required String partnerId,
    required Function(RTCIceCandidate candidate) onIceCandidateGenerated,
  }) async {
    _currentCallId = callId;
    _currentPartnerId = partnerId;
    _isCaller = true;
    _isMuted = false;
    _isSpeakerOn = false;
    _hasSetRemoteDescription = false;
    _hasAttemptedIceRestart = false;
    _pendingRemoteCandidates.clear();

    try {
      debugPrint('🎙️ [WebRTC Caller] Đang mở Microphone...');
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      final rtcConfig = await _getEffectiveIceConfiguration();
      _peerConnection = await createPeerConnection(rtcConfig);

      // Đưa Audio Track vào Peer Connection
      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      _setupPeerConnectionListeners(onIceCandidateGenerated);

      // Âm thanh mặc định ra TAI NGHE (earpiece)
      await Helper.setSpeakerphoneOn(false);

      // Tạo SDP Offer
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await _peerConnection!.setLocalDescription(offer);

      debugPrint('📤 [WebRTC Caller] SDP Offer đã được tạo thành công');
      return offer.toMap();
    } catch (e) {
      debugPrint('⚠️ [WebRTC Caller] Lỗi khi initiateCall: $e');
      await endCall(notifyPeer: false, reason: 'Lỗi khởi tạo âm thanh WebRTC');
      return null;
    }
  }

  /// Trả lời cuộc gọi phía Người nhận (Receiver)
  Future<Map<String, dynamic>?> answerCall({
    required String callId,
    required String callerId,
    required dynamic offerSdp,
    required Function(RTCIceCandidate candidate) onIceCandidateGenerated,
  }) async {
    _currentCallId = callId;
    _currentPartnerId = callerId;
    _isCaller = false;
    _isMuted = false;
    _isSpeakerOn = false;
    _hasSetRemoteDescription = false;
    _hasAttemptedIceRestart = false;
    _pendingRemoteCandidates.clear();

    try {
      debugPrint('🎙️ [WebRTC Receiver] Đang mở Microphone...');
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      final rtcConfig = await _getEffectiveIceConfiguration();
      _peerConnection = await createPeerConnection(rtcConfig);

      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      _setupPeerConnectionListeners(onIceCandidateGenerated);

      // Âm thanh mặc định ra TAI NGHE (earpiece)
      await Helper.setSpeakerphoneOn(false);

      // Thiết lập Remote Description từ Offer của Caller
      final sdpDescription = RTCSessionDescription(
        offerSdp['sdp'] ?? '',
        offerSdp['type'] ?? 'offer',
      );
      await _peerConnection!.setRemoteDescription(sdpDescription);
      _hasSetRemoteDescription = true;
      debugPrint('📥 [WebRTC Receiver] Đã setRemoteDescription thành công!');

      // Xả toàn bộ candidate đang chờ trong hàng đợi
      await _flushPendingCandidates();

      // Tạo SDP Answer
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await _peerConnection!.setLocalDescription(answer);

      debugPrint('📤 [WebRTC Receiver] SDP Answer đã được tạo thành công');
      return answer.toMap();
    } catch (e) {
      debugPrint('⚠️ [WebRTC Receiver] Lỗi khi answerCall: $e');
      await endCall(notifyPeer: false, reason: 'Lỗi thiết lập cuộc gọi WebRTC');
      return null;
    }
  }

  void _setupPeerConnectionListeners(Function(RTCIceCandidate candidate) onIceCandidateGenerated) {
    if (_peerConnection == null) return;

    // Lắng nghe ICE Candidate
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        final cStr = candidate.candidate!;
        String candidateType = 'unknown';
        if (cStr.contains(' typ host')) candidateType = 'host (Local LAN)';
        if (cStr.contains(' typ srflx')) candidateType = 'srflx (STUN NAT)';
        if (cStr.contains(' typ relay')) candidateType = 'relay (TURN Relay)';

        debugPrint('🧊 [WebRTC ICE Generated] Loại: $candidateType | $cStr');
        onIceCandidateGenerated(candidate);
      }
    };

    // Lắng nghe trạng thái thu thập ICE
    _peerConnection!.onIceGatheringState = (state) {
      debugPrint('📡 [WebRTC ICE Gathering] Trạng thái: $state');
    };

    // Lắng nghe trạng thái kết nối ICE
    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('❄️ [WebRTC ICE Connection] Trạng thái: $state');
      _iceConnectionStateController.add(state);
    };

    // Lắng nghe trạng thái kết nối PeerConnection
    _peerConnection!.onConnectionState = (state) {
      debugPrint('🛰️ [WebRTC Peer State] Trạng thái: $state');
      _connectionStateController.add(state);

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        debugPrint('🎉 [WebRTC] Cuộc gọi thoại đã kết nối P2P thành công!');
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        debugPrint('⚠️ [WebRTC] Mất kết nối WebRTC (state: $state)');
        // Thử ICE restart một lần duy nhất nếu là Caller
        if (!_hasAttemptedIceRestart && _isCaller && _peerConnection != null) {
          _hasAttemptedIceRestart = true;
          debugPrint('🔄 [WebRTC] Đang thử ICE Restart 1 lần...');
          _restartIce();
        }
      }
    };

    // Lắng nghe âm thanh từ đối phương
    _peerConnection!.onTrack = (event) {
      debugPrint('🎧 [WebRTC Audio Track] Đã nhận được Remote Audio Track từ đối phương!');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
      }
    };
  }

  /// Caller nhận SDP Answer từ Receiver
  Future<void> handleRemoteAnswer(dynamic sdpMap) async {
    if (_peerConnection == null) {
      debugPrint('⚠️ [WebRTC] Bỏ qua Answer vì _peerConnection null');
      return;
    }
    try {
      final sdp = RTCSessionDescription(
        sdpMap['sdp'] ?? '',
        sdpMap['type'] ?? 'answer',
      );
      await _peerConnection!.setRemoteDescription(sdp);
      _hasSetRemoteDescription = true;
      debugPrint('✅ [WebRTC Caller] Đã thiết lập Remote Answer thành công!');

      // Xả hàng đợi candidate
      await _flushPendingCandidates();
    } catch (e) {
      debugPrint('⚠️ [WebRTC Caller] Lỗi khi setRemoteDescription (Answer): $e');
    }
  }

  /// Tiếp nhận ICE Candidate từ đối phương (hỗ trợ hàng đợi khi chưa set remote description)
  Future<void> handleRemoteCandidate(dynamic candidateMap) async {
    try {
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );

      final cStr = candidate.candidate ?? '';
      String candidateType = 'unknown';
      if (cStr.contains(' typ host')) candidateType = 'host';
      if (cStr.contains(' typ srflx')) candidateType = 'srflx';
      if (cStr.contains(' typ relay')) candidateType = 'relay';

      if (_peerConnection != null && _hasSetRemoteDescription) {
        debugPrint('📥 [WebRTC Remote Candidate] Thêm ngay ($candidateType)');
        await _peerConnection!.addCandidate(candidate);
      } else {
        debugPrint('⏳ [WebRTC Remote Candidate] Đẩy vào hàng đợi vì chưa setRemoteDescription ($candidateType)');
        _pendingRemoteCandidates.add(candidate);
      }
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi khi xử lý Remote Candidate: $e');
    }
  }

  /// Xả toàn bộ Candidate đang chờ trong hàng đợi
  Future<void> _flushPendingCandidates() async {
    if (_peerConnection == null || !_hasSetRemoteDescription) return;
    if (_pendingRemoteCandidates.isEmpty) return;

    debugPrint('🚀 [WebRTC ICE Queue] Đang xả ${_pendingRemoteCandidates.length} candidate...');
    final candidatesToAdd = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();

    for (final candidate in candidatesToAdd) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('⚠️ [WebRTC ICE Queue] Lỗi thêm candidate từ hàng đợi: $e');
      }
    }
    debugPrint('✅ [WebRTC ICE Queue] Đã xả xong toàn bộ hàng đợi!');
  }

  /// Thử ICE restart khi mạng bị đứt
  Future<void> _restartIce() async {
    if (_peerConnection == null) return;
    try {
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
        'iceRestart': true,
      });
      await _peerConnection!.setLocalDescription(offer);
      debugPrint('🔄 [WebRTC] Đã tạo ICE Restart Offer');
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi ICE restart: $e');
    }
  }

  /// Bật / Tắt Microphone của chính mình
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }
    debugPrint('🎤 [WebRTC] Trạng thái Microphone: ${_isMuted ? "ĐÃ TẮT MIC (Muted)" : "ĐANG BẬT MIC"}');
  }

  /// Chuyển đổi Loa Ngoài / Tai Nghe
  Future<bool> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
      debugPrint('🔊 [WebRTC] Chuyển đổi đường ra âm thanh: ${_isSpeakerOn ? "LOA NGOÀI" : "TAI NGHE (Earpiece)"}');
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi chuyển đổi loa ngoài: $e');
    }
    return _isSpeakerOn;
  }

  /// Kết thúc cuộc gọi và giải phóng toàn bộ tài nguyên WebRTC
  Future<void> endCall({bool notifyPeer = false, String? reason}) async {
    debugPrint('🛑 [WebRTC] Kết thúc cuộc gọi WebRTC (notifyPeer=$notifyPeer, reason=$reason)');

    _isMuted = false;
    _isSpeakerOn = false;
    _currentCallId = null;
    _currentPartnerId = null;
    _hasSetRemoteDescription = false;
    _hasAttemptedIceRestart = false;
    _pendingRemoteCandidates.clear();

    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      if (_remoteStream != null) {
        for (final track in _remoteStream!.getTracks()) {
          track.stop();
        }
        await _remoteStream!.dispose();
        _remoteStream = null;
      }

      if (_peerConnection != null) {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
        _peerConnection = null;
      }

      // Đưa âm thanh về tai nghe hoặc mặc định
      await Helper.setSpeakerphoneOn(false);
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi khi dọn dẹp tài nguyên cuộc gọi: $e');
    }

    _callEndedController.add(reason);
  }
}
