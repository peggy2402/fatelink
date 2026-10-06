import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/anonymous_avatar_helper.dart';
import '../../../services/call_manager.dart';

/// Màn hình Route toàn màn hình cho cuộc gọi thoại Real-time FateLink (Cosmic Voice Call Screen)
/// Thiết kế chuẩn Cosmic UI/UX, hỗ trợ cả 2 trạng thái: Cuộc gọi đến & Đàm thoại 2 chiều.
/// Chặn thao tác Back vô tình bằng PopScope để bảo toàn phiên kết nối WebRTC.
class CosmicVoiceCallScreen extends StatefulWidget {
  const CosmicVoiceCallScreen({super.key});

  @override
  State<CosmicVoiceCallScreen> createState() => _CosmicVoiceCallScreenState();
}

class _CosmicVoiceCallScreenState extends State<CosmicVoiceCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onBackPressed() {
    // Nếu đang trong cuộc gọi, hiển thị xác nhận cúp máy
    if (CallManager.instance.isInCall) {
      showDialog(
        context: context,
        builder: (ctx) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF131A2A).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: const Text(
              'Kết thúc cuộc gọi?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'BeVietnamPro',
              ),
            ),
            content: const Text(
              'Bạn có chắc chắn muốn ngắt kết nối cuộc gọi thoại này không?',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontFamily: 'BeVietnamPro',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Ở lại',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4757),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  CallManager.instance.hangUp();
                },
                child: const Text(
                  'Cúp máy',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final callManager = CallManager.instance;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080B14),
        body: ValueListenableBuilder<CallState>(
          valueListenable: callManager.stateNotifier,
          builder: (context, callState, _) {
            final session = callManager.currentSession;
            final partnerName = session?.partnerName ?? 'Bạn tâm giao';
            final partnerAvatar = session?.partnerAvatar;
            final partnerId = session?.partnerId ?? '';

            return Stack(
              children: [
                // 1. Phông nền vũ trụ Cosmic Gradient động
                _buildCosmicBackground(),

                // 2. Nội dung chính toàn màn hình
                SafeArea(
                  child: Column(
                    children: [
                      // Thanh tiêu đề thu nhỏ / thoát an toàn
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 30),
                              onPressed: _onBackPressed,
                              tooltip: 'Thu nhỏ',
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_outline, size: 14, color: Color(0xFF00F5D4)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'P2P WebRTC Mã hóa',
                                    style: TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'BeVietnamPro',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48), // Cân bằng không gian
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Avatar lớn trung tâm kèm sóng rung cảm Cosmic
                      _buildPulsatingAvatar(partnerName, partnerAvatar, partnerId, callState),

                      const SizedBox(height: 28),

                      // Tên đối tác
                      Text(
                        partnerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Trạng thái cuộc gọi / Đồng hồ đếm giờ
                      _buildCallStatusBadge(callState),

                      const Spacer(flex: 2),

                      // Bảng điều khiển nút bấm chức năng
                      _buildActionControls(callState),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Nền không gian Cosmic với các đốm sáng gradient huyền ảo
  Widget _buildCosmicBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFF1E163B), // Tím cosmic sâu
              Color(0xFF0D1122), // Xanh đêm
              Color(0xFF080B14), // Đen vũ trụ
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  /// Avatar với các vòng tròn aura rung động theo nhịp sóng âm
  Widget _buildPulsatingAvatar(
    String partnerName,
    String? partnerAvatar,
    String partnerId,
    CallState callState,
  ) {
    final auraGradient = AnonymousAvatarHelper.getCosmicAuraGradient(partnerId);
    final primaryGlow = auraGradient.colors.first;

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rippleController]),
        builder: (context, child) {
          final isPulsing = callState == CallState.incomingRinging ||
              callState == CallState.outgoingRinging ||
              callState == CallState.connecting;

          return SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vòng sóng lan tỏa 1
                if (isPulsing)
                  Transform.scale(
                    scale: 1.0 + (_rippleController.value * 0.45),
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryGlow.withValues(
                            alpha: (1.0 - _rippleController.value) * 0.45,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                // Vòng hào quang phát sáng 2
                Container(
                  width: 154 * (isPulsing ? _pulseAnimation.value : 1.0),
                  height: 154 * (isPulsing ? _pulseAnimation.value : 1.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGlow.withValues(alpha: 0.35),
                        blurRadius: 36,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Hình ảnh đại diện chính (Avatar)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: auraGradient,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: partnerAvatar != null && partnerAvatar.isNotEmpty
                        ? Image.network(
                            partnerAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(partnerId),
                          )
                        : _buildFallbackAvatar(partnerId),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackAvatar(String partnerId) {
    final asset = AnonymousAvatarHelper.getAnonymousAvatarAsset(partnerId);
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 70, color: Colors.white70),
    );
  }

  /// Trạng thái cuộc gọi / Đồng hồ đếm giây
  Widget _buildCallStatusBadge(CallState callState) {
    if (callState == CallState.connected) {
      return ValueListenableBuilder<int>(
        valueListenable: CallManager.instance.durationSecondsNotifier,
        builder: (context, seconds, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF2ED573).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ED573),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(seconds),
                  style: const TextStyle(
                    color: Color(0xFF2ED573),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    String text;
    Color textColor;
    switch (callState) {
      case CallState.outgoingRinging:
        text = 'Đang đổ chuông...';
        textColor = const Color(0xFF38BDF8);
        break;
      case CallState.incomingRinging:
        text = 'Cuộc gọi thoại đến từ Vũ Trụ...';
        textColor = const Color(0xFFA855F7);
        break;
      case CallState.connecting:
        text = 'Đang kết nối tần số âm thanh...';
        textColor = const Color(0xFFFBBF24);
        break;
      case CallState.ended:
        text = 'Cuộc gọi đã kết thúc';
        textColor = const Color(0xFF94A3B8);
        break;
      case CallState.idle:
      default:
        text = 'Sẵn sàng kết nối';
        textColor = const Color(0xFF94A3B8);
    }

    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        fontFamily: 'BeVietnamPro',
      ),
    );
  }

  /// Bảng nút bấm điều khiển
  Widget _buildActionControls(CallState callState) {
    if (callState == CallState.incomingRinging) {
      // 2 Nút lớn: Từ chối & Nhận cuộc gọi
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Nút Từ chối (Đỏ)
            _buildRoundActionButton(
              icon: Icons.call_end,
              label: 'Từ chối',
              color: const Color(0xFFFF4757),
              size: 72,
              onTap: () {
                HapticFeedback.heavyImpact();
                CallManager.instance.rejectIncomingCall();
              },
            ),

            // Nút Trả lời (Xanh)
            _buildRoundActionButton(
              icon: Icons.call,
              label: 'Trả lời',
              color: const Color(0xFF2ED573),
              size: 72,
              onTap: () {
                HapticFeedback.heavyImpact();
                CallManager.instance.acceptIncomingCall();
              },
            ),
          ],
        ),
      );
    }

    // Các nút chức năng trong cuộc gọi (Mute, Speaker, Hangup)
    final callManager = CallManager.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Nút Mic (Tắt/Bật Mic)
          ValueListenableBuilder<bool>(
            valueListenable: callManager.isMutedNotifier,
            builder: (context, isMuted, _) {
              return _buildRoundActionButton(
                icon: isMuted ? Icons.mic_off : Icons.mic,
                label: isMuted ? 'Bật mic' : 'Tắt mic',
                color: isMuted ? Colors.white : Colors.white.withValues(alpha: 0.15),
                iconColor: isMuted ? const Color(0xFF0F172A) : Colors.white,
                size: 60,
                onTap: () {
                  HapticFeedback.selectionClick();
                  callManager.toggleMute();
                },
              );
            },
          ),

          // Nút Cúp máy (Đỏ)
          _buildRoundActionButton(
            icon: Icons.call_end,
            label: 'Cúp máy',
            color: const Color(0xFFFF4757),
            size: 72,
            onTap: () {
              HapticFeedback.heavyImpact();
              callManager.hangUp();
            },
          ),

          // Nút Loa ngoài (Speaker / Earpiece)
          ValueListenableBuilder<bool>(
            valueListenable: callManager.isSpeakerOnNotifier,
            builder: (context, isSpeakerOn, _) {
              return _buildRoundActionButton(
                icon: isSpeakerOn ? Icons.volume_up : Icons.phone_in_talk,
                label: isSpeakerOn ? 'Loa ngoài' : 'Tai nghe',
                color: isSpeakerOn ? Colors.white : Colors.white.withValues(alpha: 0.15),
                iconColor: isSpeakerOn ? const Color(0xFF0F172A) : Colors.white,
                size: 60,
                onTap: () {
                  HapticFeedback.selectionClick();
                  callManager.toggleSpeaker();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoundActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color iconColor = Colors.white,
    required double size,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.44),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'BeVietnamPro',
          ),
        ),
      ],
    );
  }
}
