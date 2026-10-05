import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal đàm thoại trực tiếp giữa 2 người dùng (Cosmic Soulmate Voice Call)
class CosmicVoiceCallModal extends StatefulWidget {
  final String partnerName;
  final String? partnerAvatar;
  final String partnerId;

  const CosmicVoiceCallModal({
    super.key,
    required this.partnerName,
    required this.partnerId,
    this.partnerAvatar,
  });

  static void show(
    BuildContext context, {
    required String partnerName,
    required String partnerId,
    String? partnerAvatar,
  }) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CosmicVoiceCallModal(
        partnerName: partnerName,
        partnerId: partnerId,
        partnerAvatar: partnerAvatar,
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
  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // 1. Kích hoạt nhịp rung chuông điện thoại thực tế (Ringing vibration pattern)
    HapticFeedback.heavyImpact();
    _ringVibrationTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 250), () {
        HapticFeedback.mediumImpact();
      });
    });

    // 2. Kết nối đàm thoại trực tiếp sau chuông reo
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _ringVibrationTimer?.cancel();
        setState(() => _isConnected = true);
        HapticFeedback.mediumImpact();
        _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _seconds++);
        });
      }
    });
  }

  @override
  void dispose() {
    _ringVibrationTimer?.cancel();
    _pulseController.dispose();
    _callTimer?.cancel();
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
                            ? 'Đang đàm thoại • ${_formatDuration(_seconds)}'
                            : 'Đang kết nối tần số tâm hồn...',
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

                    // Thanh sóng âm thanh sống động
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(12, (index) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final factor = (index % 3 == 0)
                                ? _pulseController.value
                                : (1 - _pulseController.value);
                            return Container(
                              width: 3.5,
                              height: 12 + (factor * 26),
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
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
                            setState(() => _isMuted = !_isMuted);
                          },
                        ),

                        // Nút Kết thúc cuộc gọi màu đỏ
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEF4444),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFEF4444),
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
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isSpeakerOn = !_isSpeakerOn);
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
