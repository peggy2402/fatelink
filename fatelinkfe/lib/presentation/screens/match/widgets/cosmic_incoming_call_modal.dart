import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/utils/toast_utils.dart';
import 'cosmic_voice_call_modal.dart';

/// Modal hiển thị cuộc gọi đến (Cosmic Incoming Voice Call)
/// Phong cách Apple iOS & Cosmic Dark Glassmorphism
class CosmicIncomingCallModal extends StatefulWidget {
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final IO.Socket socket;
  final dynamic offerSdp;

  const CosmicIncomingCallModal({
    super.key,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.socket,
    this.offerSdp,
  });

  static void show(
    BuildContext context, {
    required String callerId,
    required String callerName,
    String? callerAvatar,
    required IO.Socket socket,
    dynamic offerSdp,
  }) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CosmicIncomingCallModal(
        callerId: callerId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        socket: socket,
        offerSdp: offerSdp,
      ),
    );
  }

  @override
  State<CosmicIncomingCallModal> createState() => _CosmicIncomingCallModalState();
}

class _CosmicIncomingCallModalState extends State<CosmicIncomingCallModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _vibrationTimer;
  bool _isActionTaken = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Chu kỳ rung chuông cuộc gọi đến
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.mediumImpact();
      });
    });

    // Lắng nghe nếu caller cúp máy trước khi nghe
    widget.socket.on('voiceCallEnded', _handleCallerCanceled);
  }

  void _handleCallerCanceled(dynamic data) {
    if (!mounted || _isActionTaken) return;
    _isActionTaken = true;
    _vibrationTimer?.cancel();
    Navigator.of(context, rootNavigator: true).pop();
    ToastUtil.showInfo(context, 'Cuộc gọi thoại đã kết thúc');
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _pulseController.dispose();
    widget.socket.off('voiceCallEnded', _handleCallerCanceled);
    super.dispose();
  }

  Future<void> _handleDecline() async {
    if (_isActionTaken) return;
    _isActionTaken = true;
    HapticFeedback.heavyImpact();
    _vibrationTimer?.cancel();

    // Báo cho caller biết cuộc gọi bị từ chối
    widget.socket.emit('rejectVoiceCall', {
      'callerId': widget.callerId,
      'reason': 'declined',
    });

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _handleAccept() async {
    if (_isActionTaken) return;
    _isActionTaken = true;
    HapticFeedback.heavyImpact();
    _vibrationTimer?.cancel();

    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop(); // Đóng modal cuộc gọi đến

    // Mở màn hình đàm thoại với vai trò Người nhận (Receiver)
    if (mounted) {
      CosmicVoiceCallModal.show(
        context,
        partnerName: widget.callerName,
        partnerId: widget.callerId,
        partnerAvatar: widget.callerAvatar,
        socket: widget.socket,
        isIncomingAccept: true,
        offerSdp: widget.offerSdp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
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
                      const Color(0xFF10B981).withValues(alpha: 0.22),
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
                      const Color(0xFFEC4899).withValues(alpha: 0.2),
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

                    // Tiêu đề cuộc gọi đến
                    const Text(
                      'CUỘC GỌI THOẠI ĐẾN',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: Color(0xFFA78BFA),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tên người gọi
                    Text(
                      widget.callerName,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đang kết nối tần số tâm hồn...',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),

                    const Spacer(),

                    // Avatar nhấp nháy hào quang sóng âm
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 140 + (_pulseController.value * 28),
                            height: 140 + (_pulseController.value * 28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF10B981).withValues(
                                    alpha: 0.35 * (1 - _pulseController.value),
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 110,
                                height: 110,
                                padding: const EdgeInsets.all(3.5),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF6366F1)],
                                  ),
                                ),
                                child: ClipOval(
                                  child: widget.callerAvatar != null &&
                                          widget.callerAvatar!.isNotEmpty
                                      ? Image.network(
                                          widget.callerAvatar!,
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

                    // 2 Nút điều khiển: Từ chối (Đỏ) & Trả lời (Xanh)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Nút Từ chối
                          GestureDetector(
                            onTap: _handleDecline,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
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
                                const SizedBox(height: 10),
                                const Text(
                                  'Từ chối',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Nút Trả lời
                          GestureDetector(
                            onTap: _handleAccept,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF10B981),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x6610B981),
                                        blurRadius: 18,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Trả lời',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF6366F1),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}
