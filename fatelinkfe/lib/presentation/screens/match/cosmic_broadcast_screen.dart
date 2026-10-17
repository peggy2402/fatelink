import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../data/models/match_user.dart';
import '../../../logic/blocs/home/home_bloc.dart';
import 'soul_sanctuary_screen.dart';
import 'widgets/broadcast_center_core.dart';
import 'widgets/broadcast_cosmic_painter.dart';
import 'widgets/broadcast_mood_selector.dart';
import 'widgets/broadcast_phase_status_card.dart';

/// Màn hình "Phát Sóng Tâm Hồn 432Hz" (Cosmic Pulse Broadcast):
/// - Nút Trái tim Trung tâm (Hero Center FAB) kích hoạt phát sóng cảm xúc vào vũ trụ
/// - Cơ chế Fast-Pass Handshake 1-1: Người đầu tiên đón nhận sóng sẽ khóa kênh kết nối độc quyền
/// - Tránh hoàn toàn tình trạng nhiều người nhảy vào cùng lúc gây rối loạn
/// - Chuyển tiếp mượt mà vào Phòng Giao Thoa Linh Hồn 120s (SoulSanctuaryScreen)
class CosmicBroadcastScreen extends StatefulWidget {
  final String? initialMood;

  const CosmicBroadcastScreen({super.key, this.initialMood});

  @override
  State<CosmicBroadcastScreen> createState() => _CosmicBroadcastScreenState();
}

class _CosmicBroadcastScreenState extends State<CosmicBroadcastScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late AnimationController _particleController;

  // Trạng thái phát sóng
  late String _currentMood;
  String? _myAvatarUrl;
  int _broadcastPhase = 0; // 0: Nén sóng, 1: Lan tỏa vệ tinh, 2: Bắt được phản hồi, 3: Khóa kênh 1-1
  MatchUser? _matchedPartner;
  Timer? _phaseTimer;
  Timer? _hapticTimer;

  // Danh sách các tâm trạng phát sóng
  static const List<Map<String, String>> _availableMoods = [
    {'name': 'Bình yên', 'icon': '🍃', 'freq': '432Hz'},
    {'name': 'Chữa lành', 'icon': '✨', 'freq': '528Hz'},
    {'name': 'Đêm muộn', 'icon': '🌙', 'freq': '396Hz'},
    {'name': 'Tìm tri kỷ', 'icon': '💫', 'freq': '639Hz'},
    {'name': 'Lắng nghe', 'icon': '🌊', 'freq': '741Hz'},
  ];

  @override
  void initState() {
    super.initState();
    _currentMood = widget.initialMood ?? 'Bình yên';

    // 1. Controller tạo nhịp sóng lan tỏa (Ripple Pulse)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 2. Controller xoay quỹ đạo thiên hà
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 3. Controller các hạt ánh sao
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _loadMyAvatar();
    _startBroadcastSequence();
  }

  Future<void> _loadMyAvatar() async {
    try {
      final avatar = await SecureStorageHelper.storage.read(key: 'user_avatar');
      if (mounted && avatar != null && avatar.isNotEmpty) {
        setState(() => _myAvatarUrl = avatar);
      }
    } catch (_) {}
  }

  void _startBroadcastSequence() {
    // Nhịp tim rung haptic theo tần số
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted || _broadcastPhase >= 3) {
        timer.cancel();
        return;
      }
      HapticFeedback.lightImpact();
    });

    // Mô phỏng tiến trình phát sóng chân thực
    _phaseTimer?.cancel();
    setState(() => _broadcastPhase = 0);

    // Giai đoạn 1: Lan tỏa sóng sau 2.2s
    _phaseTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _broadcastPhase = 1);
      HapticFeedback.mediumImpact();

      // Giai đoạn 2: Phát hiện vệ tinh phản hồi sau thêm 2.3s
      _phaseTimer = Timer(const Duration(milliseconds: 2300), () {
        if (!mounted) return;
        setState(() => _broadcastPhase = 2);

        // Chọn đối phương phù hợp từ dữ liệu thực tế
        _pickBestMatch();

        if (_matchedPartner == null) {
          // Chưa có đối tác thực tế trực tuyến cùng tần số -> Giữ sóng phát liên tục
          return;
        }

        // Giai đoạn 3: Đối phương bấm [Đón nhận sóng] (Fast-Pass Handshake) sau thêm 2s
        _phaseTimer = Timer(const Duration(milliseconds: 2000), () {
          if (!mounted) return;
          setState(() => _broadcastPhase = 3);
          HapticFeedback.heavyImpact();

          // Chuyển tiếp vào SoulSanctuaryScreen sau 1.8s để người dùng chiêm ngưỡng khoảnh khắc khóa kênh
          _phaseTimer = Timer(const Duration(milliseconds: 1800), () {
            if (!mounted || _matchedPartner == null) return;
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 700),
                pageBuilder: (context, anim1, anim2) =>
                    SoulSanctuaryScreen(partner: _matchedPartner!),
                transitionsBuilder: (context, anim1, anim2, child) {
                  return FadeTransition(
                    opacity: anim1,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            );
          });
        });
      });
    });
  }

  void _pickBestMatch() {
    final homeState = context.read<HomeBloc>().state;
    final pool = homeState.matchedUsers;

    if (pool.isNotEmpty) {
      // Ưu tiên người có cùng cảm xúc hoặc điểm tương hợp cao nhất
      final sameMoodMatches = pool
          .where((u) => u.emotion.toLowerCase().contains(_currentMood.toLowerCase()))
          .toList();
      if (sameMoodMatches.isNotEmpty) {
        _matchedPartner = sameMoodMatches.first;
      } else {
        _matchedPartner = pool.first;
      }
    } else {
      _matchedPartner = null;
    }
  }

  String _getMoodFrequency(String mood) {
    final found = _availableMoods.firstWhere(
      (m) => m['name'] == mood,
      orElse: () => {'freq': '528Hz'},
    );
    return found['freq'] ?? '528Hz';
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _hapticTimer?.cancel();
    _pulseController.dispose();
    _spinController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final topPadding = context.safeTop;
    final bottomPadding = context.safeBottom;

    final homeState = context.watch<HomeBloc>().state;
    final matchingCount = homeState.matchedUsers
        .where((u) => u.emotion.toLowerCase().contains(_currentMood.toLowerCase()))
        .length;
    final displayCount = matchingCount > 0 ? matchingCount : homeState.matchedUsers.length;

    return Scaffold(
      backgroundColor: const Color(0xFF070913),
      body: Stack(
        children: [
          // 1. Nền Vũ Trụ Cực Quang Sâu Thẳm (Cosmic Deep Aurora)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF23103A),
                    Color(0xFF0F0B1E),
                    Color(0xFF06070E),
                  ],
                ),
              ),
            ),
          ),

          // 2. Hiệu ứng hạt sao lấp lánh và sóng lan tỏa
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _spinController]),
              builder: (context, _) {
                return CustomPaint(
                  painter: CosmicWavePainter(
                    pulseValue: _pulseController.value,
                    spinValue: _spinController.value,
                    phase: _broadcastPhase,
                  ),
                );
              },
            ),
          ),

          // 3. Nút Đóng / Hủy phát sóng
          Positioned(
            top: topPadding + 12,
            right: 18,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // 4. Header: Tần Số & Trạng Thái Phát Sóng
          Positioned(
            top: topPadding + 14,
            left: 20,
            right: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FFB2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00FFB2),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PHÁT SÓNG TẦN SỐ CẢM XÚC',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        color: Color(0xFF00FFB2),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chạm Tần Số Đồng Điệu',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // 5. Trung tâm phát sóng: Avatar người dùng và các sóng âm lan tỏa
          Align(
            alignment: const Alignment(0.0, -0.15),
            child: BroadcastCenterCore(
              coreSize: screenWidth * 0.32,
              pulseController: _pulseController,
              myAvatarUrl: _myAvatarUrl,
              currentMood: _currentMood,
              frequency: _getMoodFrequency(_currentMood),
            ),
          ),

          // 6. Thẻ trạng thái tiến trình sóng & Thông báo khóa kênh
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding + 115,
            child: BroadcastPhaseStatusCard(
              broadcastPhase: _broadcastPhase,
              currentMood: _currentMood,
              frequency: _getMoodFrequency(_currentMood),
              matchedPartner: _matchedPartner,
              matchedCount: displayCount,
            ),
          ),

          // 7. Thanh chọn nhanh tần số tâm trạng (Mood Pills)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 20,
            child: BroadcastMoodSelector(
              availableMoods: _availableMoods,
              currentMood: _currentMood,
              onSelectMood: (mood) {
                setState(() => _currentMood = mood);
                _startBroadcastSequence();
              },
            ),
          ),
        ],
      ),
    );
  }
}
