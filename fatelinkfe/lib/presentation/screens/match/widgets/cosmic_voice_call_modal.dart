import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/services/webrtc_voice_call_service.dart';
import '../../../../core/utils/toast_utils.dart';

/// Modal đàm thoại trực tiếp giữa 2 người dùng (Cosmic Soulmate Voice Call)
/// Tích hợp WebRTC P2P Audio Stream 2 chiều & WebSocket Signaling thực tế.
class CosmicVoiceCallModal extends StatefulWidget {
  final String partnerName;
  final String? partnerAvatar;
  final String partnerId;
  final IO.Socket socket;
  final bool isIncomingAccept;
  final dynamic offerSdp;

  const CosmicVoiceCallModal({
    super.key,
    required this.partnerName,
    required this.partnerId,
    required this.socket,
    this.partnerAvatar,
    this.isIncomingAccept = false,
    this.offerSdp,
  });

  static void show(
    BuildContext context, {
    required String partnerName,
    required String partnerId,
    required IO.Socket socket,
    String? partnerAvatar,
    bool isIncomingAccept = false,
    dynamic offerSdp,
  }) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CosmicVoiceCallModal(
        partnerName: partnerName,
        partnerId: partnerId,
        partnerAvatar: partnerAvatar,
        socket: socket,
        isIncomingAccept: isIncomingAccept,
        offerSdp: offerSdp,
      ),
    );
  }

  @override
  State<CosmicVoiceCallModal> createState() => _CosmicVoiceCallModalState();
}

class _CosmicVoiceCallModalState extends State<CosmicVoiceCallModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _callTimer;
  Timer? _ringVibrationTimer;
  StreamSubscription? _connSub;
  StreamSubscription? _endSub;

  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  String _statusText = 'Đang kết nối tần số tâm hồn...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _listenServiceStreams();
    _listenSocketEvents();

    if (widget.isIncomingAccept) {
      // Người nhận: trả lời cuộc gọi
      _statusText = 'Đang kết nối đàm thoại...';
      WebRtcVoiceCallService().answerCall(
        socket: widget.socket,
        callerId: widget.partnerId,
        offerSdp: widget.offerSdp,
      );
    } else {
      // Người gọi: bắt đầu chuông và khởi tạo WebRTC
      _statusText = 'Đang đổ chuông...';
      _startRingingVibration();
      WebRtcVoiceCallService().initiateCall(
        socket: widget.socket,
        partnerId: widget.partnerId,
      );
    }
  }

  void _startRingingVibration() {
    HapticFeedback.heavyImpact();
    _ringVibrationTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!_isConnected && mounted) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 250), () {
          HapticFeedback.mediumImpact();
        });
      }
    });
  }

  void _listenServiceStreams() {
    _connSub = WebRtcVoiceCallService().onConnectionStateChanged.listen((connected) {
      if (!mounted) return;
      if (connected && !_isConnected) {
        _ringVibrationTimer?.cancel();
        setState(() {
          _isConnected = true;
          _statusText = 'Đang đàm thoại';
        });
        HapticFeedback.mediumImpact();
        _callTimer?.cancel();
        _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _seconds++);
        });
      }
    });

    _endSub = WebRtcVoiceCallService().onCallEnded.listen((reason) {
      if (!mounted) return;
      _ringVibrationTimer?.cancel();
      _callTimer?.cancel();
      Navigator.of(context, rootNavigator: true).pop();
      if (reason != null && reason.isNotEmpty) {
        ToastUtil.showInfo(context, reason);
      }
    });
  }

  void _listenSocketEvents() {
    // 1. Phản hồi khi máy đối phương đang đổ chuông
    widget.socket.on('voiceCallRinging', _onVoiceCallRinging);

    // 2. Đối phương chấp nhận cuộc gọi
    widget.socket.on('voiceCallAccepted', _onVoiceCallAccepted);

    // 3. Đối phương từ chối cuộc gọi
    widget.socket.on('voiceCallRejected', _onVoiceCallRejected);

    // 4. Đối phương offline hoặc không thể kết nối
    widget.socket.on('voiceCallUnavailable', _onVoiceCallUnavailable);

    // 5. Đối phương bấm kết thúc cuộc gọi
    widget.socket.on('voiceCallEnded', _onVoiceCallEnded);

    // 6. Nhận SDP Answer từ đối phương
    widget.socket.on('webrtcAnswer', _onWebRtcAnswer);

    // 7. Nhận ICE Candidate từ đối phương
    widget.socket.on('iceCandidate', _onIceCandidate);
  }

  void _onVoiceCallRinging(dynamic data) {
    if (!mounted || _isConnected) return;
    setState(() => _statusText = 'Đang đổ chuông...');
  }

  void _onVoiceCallAccepted(dynamic data) {
    if (!mounted) return;
    _ringVibrationTimer?.cancel();
    setState(() {
      _isConnected = true;
      _statusText = 'Đang đàm thoại';
    });
    HapticFeedback.mediumImpact();
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _onVoiceCallRejected(dynamic data) {
    if (!mounted) return;
    _ringVibrationTimer?.cancel();
    ToastUtil.showInfo(context, 'Đối phương hiện đang bận hoặc từ chối');
    _handleCloseAndCleanup();
  }

  void _onVoiceCallUnavailable(dynamic data) {
    if (!mounted) return;
    _ringVibrationTimer?.cancel();
    ToastUtil.showInfo(context, 'Đối phương hiện không trực tuyến');
    _handleCloseAndCleanup();
  }

  void _onVoiceCallEnded(dynamic data) {
    if (!mounted) return;
    _ringVibrationTimer?.cancel();
    _callTimer?.cancel();
    ToastUtil.showInfo(context, 'Cuộc gọi thoại đã kết thúc');
    _handleCloseAndCleanup();
  }

  void _onWebRtcAnswer(dynamic data) {
    if (data != null && data['sdp'] != null) {
      WebRtcVoiceCallService().handleRemoteAnswer(data['sdp']);
    }
  }

  void _onIceCandidate(dynamic data) {
    if (data != null && data['candidate'] != null) {
      WebRtcVoiceCallService().handleRemoteCandidate(data['candidate']);
    }
  }

  void _handleCloseAndCleanup() {
    WebRtcVoiceCallService().endCall();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    _ringVibrationTimer?.cancel();
    _callTimer?.cancel();
    _connSub?.cancel();
    _endSub?.cancel();
    _pulseController.dispose();

    // Hủy đăng ký socket listener của màn hình này
    widget.socket.off('voiceCallRinging', _onVoiceCallRinging);
    widget.socket.off('voiceCallAccepted', _onVoiceCallAccepted);
    widget.socket.off('voiceCallRejected', _onVoiceCallRejected);
    widget.socket.off('voiceCallUnavailable', _onVoiceCallUnavailable);
    widget.socket.off('voiceCallEnded', _onVoiceCallEnded);
    widget.socket.off('webrtcAnswer', _onWebRtcAnswer);
    widget.socket.off('iceCandidate', _onIceCandidate);

    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: Stack(
          children: [
            // Quầng sáng tinh vân vũ trụ
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFEC4899).withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Thanh gạt modal
                    Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Tên và Trạng thái đàm thoại
                    Text(
                      widget.partnerName,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isConnected
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _isConnected
                            ? '$_statusText • ${_formatDuration(_seconds)}'
                            : _statusText,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _isConnected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFA78BFA),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Avatar phát sóng nhịp đập Soulmate
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 130 + (_pulseController.value * 25),
                            height: 130 + (_pulseController.value * 25),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFEC4899).withValues(
                                    alpha: 0.35 * (1 - _pulseController.value),
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 104,
                                height: 104,
                                padding: const EdgeInsets.all(3.5),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                  ),
                                ),
                                child: ClipOval(
                                  child: widget.partnerAvatar != null &&
                                          widget.partnerAvatar!.isNotEmpty
                                      ? Image.network(
                                          widget.partnerAvatar!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              _buildDefaultAvatar(),
                                        )
                                      : _buildDefaultAvatar(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const Spacer(),

                    // Thanh sóng âm thanh sống động (chỉ nhảy mạnh khi đã kết nối)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(14, (index) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final factor = _isConnected
                                ? ((index % 3 == 0)
                                    ? _pulseController.value
                                    : (1 - _pulseController.value))
                                : 0.2;
                            return Container(
                              width: 3.5,
                              height: 8 + (factor * 28),
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              decoration: BoxDecoration(
                                color: _isConnected
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 36),

                    // Hàng nút điều khiển cuộc gọi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Nút Mute
                        _buildCallActionButton(
                          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: _isMuted ? 'Bật Mic' : 'Tắt Mic',
                          isActive: _isMuted,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            WebRtcVoiceCallService().toggleMute();
                            setState(() => _isMuted = WebRtcVoiceCallService().isMuted);
                          },
                        ),

                        // Nút Kết thúc cuộc gọi màu đỏ
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _handleCloseAndCleanup();
                          },
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEF4444),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66EF4444),
                                  blurRadius: 18,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),

                        // Nút Loa ngoài
                        _buildCallActionButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_down_rounded,
                          label: _isSpeakerOn ? 'Loa Ngoài' : 'Tai Nghe',
                          isActive: _isSpeakerOn,
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await WebRtcVoiceCallService().toggleSpeaker();
                            setState(() => _isSpeakerOn = WebRtcVoiceCallService().isSpeakerOn);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF8B5CF6),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}
