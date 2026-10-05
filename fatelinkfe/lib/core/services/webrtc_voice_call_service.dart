import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Dịch vụ quản lý kết nối cuộc gọi thoại Real-time qua WebRTC (P2P Audio Stream)
/// và điều phối Signaling qua WebSocket (Socket.IO).
class WebRtcVoiceCallService {
  static final WebRtcVoiceCallService _instance = WebRtcVoiceCallService._internal();
  factory WebRtcVoiceCallService() => _instance;
  WebRtcVoiceCallService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  IO.Socket? _socket;
  String? _currentPartnerId;

  bool _isCaller = false;
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  // Stream Controllers để cập nhật trạng thái ra UI
  final _connectionStateController = StreamController<bool>.broadcast();
  final _callEndedController = StreamController<String?>.broadcast();

  Stream<bool> get onConnectionStateChanged => _connectionStateController.stream;
  Stream<String?> get onCallEnded => _callEndedController.stream;

  bool get isCaller => _isCaller;
  bool get isConnected => _isConnected;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get currentPartnerId => _currentPartnerId;

  // Cấu hình máy chủ STUN công khai chất lượng cao của Google
  static const Map<String, dynamic> _iceServersConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Khởi tạo kết nối cuộc gọi phía Người gọi (Caller)
  Future<bool> initiateCall({
    required IO.Socket socket,
    required String partnerId,
  }) async {
    _socket = socket;
    _currentPartnerId = partnerId;
    _isCaller = true;
    _isConnected = false;
    _isMuted = false;
    _isSpeakerOn = true;

    try {
      // 1. Lấy luồng Microphone thực tế
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      // 2. Tạo kết nối Peer Connection
      _peerConnection = await createPeerConnection(_iceServersConfig);

      // 3. Đưa Audio Track vào Peer Connection
      for (var track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      // 4. Lắng nghe ICE Candidate và chuyển tiếp qua Socket
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate != null && _socket != null && _socket!.connected) {
          _socket!.emit('iceCandidate', {
            'partnerId': partnerId,
            'candidate': candidate.toMap(),
          });
        }
      };

      // 5. Lắng nghe trạng thái kết nối
      _peerConnection!.onConnectionState = (state) {
        debugPrint('🛰️ [WebRTC] Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _isConnected = true;
          _connectionStateController.add(true);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _isConnected = false;
          _connectionStateController.add(false);
        }
      };

      // 6. Nhận luồng âm thanh từ đối phương
      _peerConnection!.onTrack = (event) {
        debugPrint('🎧 [WebRTC] Nhận được remote audio track');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
        }
      };

      // Bật mặc định Loa ngoài
      await Helper.setSpeakerphoneOn(true);

      // 7. Tạo SDP Offer
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await _peerConnection!.setLocalDescription(offer);

      // 8. Bắn sự kiện startVoiceCall và webrtcOffer qua Socket
      _socket!.emit('startVoiceCall', {'partnerId': partnerId});
      _socket!.emit('webrtcOffer', {
        'partnerId': partnerId,
        'sdp': offer.toMap(),
      });

      return true;
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi khi initiateCall: $e');
      await endCall(reason: 'Lỗi thiết bị âm thanh');
      return false;
    }
  }

  /// Trả lời cuộc gọi phía Người nhận (Receiver)
  Future<bool> answerCall({
    required IO.Socket socket,
    required String callerId,
    required dynamic offerSdp,
  }) async {
    _socket = socket;
    _currentPartnerId = callerId;
    _isCaller = false;
    _isConnected = false;
    _isMuted = false;
    _isSpeakerOn = true;

    try {
      // 1. Lấy luồng Microphone người nhận
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      // 2. Tạo kết nối Peer Connection
      _peerConnection = await createPeerConnection(_iceServersConfig);

      // 3. Đưa Audio Track vào Peer Connection
      for (var track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      // 4. Lắng nghe ICE Candidate
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate != null && _socket != null && _socket!.connected) {
          _socket!.emit('iceCandidate', {
            'partnerId': callerId,
            'candidate': candidate.toMap(),
          });
        }
      };

      // 5. Lắng nghe trạng thái kết nối
      _peerConnection!.onConnectionState = (state) {
        debugPrint('🛰️ [WebRTC Receiver] Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _isConnected = true;
          _connectionStateController.add(true);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _isConnected = false;
          _connectionStateController.add(false);
        }
      };

      // 6. Nhận âm thanh đối phương
      _peerConnection!.onTrack = (event) {
        debugPrint('🎧 [WebRTC Receiver] Nhận được remote audio track');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
        }
      };

      await Helper.setSpeakerphoneOn(true);

      // 7. Thiết lập Remote Description từ Offer của Caller
      final sdpDescription = RTCSessionDescription(
        offerSdp['sdp'] ?? '',
        offerSdp['type'] ?? 'offer',
      );
      await _peerConnection!.setRemoteDescription(sdpDescription);

      // 8. Tạo SDP Answer
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await _peerConnection!.setLocalDescription(answer);

      // 9. Gửi phản hồi Answer và chấp nhận qua Socket
      _socket!.emit('acceptVoiceCall', {'callerId': callerId});
      _socket!.emit('webrtcAnswer', {
        'partnerId': callerId,
        'sdp': answer.toMap(),
      });

      _isConnected = true;
      _connectionStateController.add(true);
      return true;
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi khi answerCall: $e');
      await endCall(reason: 'Lỗi thiết lập cuộc gọi');
      return false;
    }
  }

  /// Caller nhận SDP Answer từ Receiver
  Future<void> handleRemoteAnswer(dynamic sdpMap) async {
    if (_peerConnection == null) return;
    try {
      final sdp = RTCSessionDescription(
        sdpMap['sdp'] ?? '',
        sdpMap['type'] ?? 'answer',
      );
      await _peerConnection!.setRemoteDescription(sdp);
      _isConnected = true;
      _connectionStateController.add(true);
      debugPrint('✅ [WebRTC] Đã thiết lập Remote Answer thành công!');
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi khi setRemoteDescription: $e');
    }
  }

  /// Tiếp nhận ICE Candidate từ đối phương
  Future<void> handleRemoteCandidate(dynamic candidateMap) async {
    if (_peerConnection == null) return;
    try {
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi khi addCandidate: $e');
    }
  }

  /// Bật / Tắt Microphone của chính mình
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }
  }

  /// Chuyển đổi Loa Ngoài / Tai Nghe
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi chuyển đổi loa ngoài: $e');
    }
  }

  /// Kết thúc cuộc gọi và giải phóng toàn bộ tài nguyên
  Future<void> endCall({String? reason}) async {
    if (_currentPartnerId != null && _socket != null && _socket!.connected) {
      _socket!.emit('endVoiceCall', {
        'partnerId': _currentPartnerId,
      });
    }

    _isConnected = false;
    _isMuted = false;
    _currentPartnerId = null;

    try {
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      if (_remoteStream != null) {
        for (var track in _remoteStream!.getTracks()) {
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
    } catch (e) {
      debugPrint('⚠️ [WebRTC] Lỗi khi giải phóng tài nguyên: $e');
    }

    _connectionStateController.add(false);
    _callEndedController.add(reason);
  }
}
