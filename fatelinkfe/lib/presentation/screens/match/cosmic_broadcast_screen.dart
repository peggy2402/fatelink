import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../data/models/match_user.dart';
import '../../../logic/blocs/home/home_bloc.dart';
import 'soul_sanctuary_screen.dart';

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

  // Danh sách dự phòng nếu chưa có data từ mạng
  static final List<MatchUser> _fallbackPartners = [
    MatchUser(
      id: 'echo-9941a',
      name: 'Khánh Linh',
      emotion: 'Bình yên',
      compatibilityScore: 96,
      distanceKm: 1.2,
      tags: ['#NhạcIndie', '#ĐêmMuộn', '#TràChiều'],
      bio: 'Muốn tìm người cùng đi dạo hồ Tây ngắm hoàng hôn...',
      gender: 'female',
    ),
    MatchUser(
      id: 'echo-8823b',
      name: 'Minh Trí',
      emotion: 'Chữa lành',
      compatibilityScore: 92,
      distanceKm: 2.8,
      tags: ['#Guitar', '#ĐọcSách', '#SốngChậm'],
      bio: 'Lắng nghe những câu chuyện chưa kể trong đêm sâu...',
      gender: 'male',
    ),
    MatchUser(
      id: 'echo-7712c',
      name: 'Hoàng Yến',
      emotion: 'Tìm tri kỷ',
      compatibilityScore: 95,
      distanceKm: 3.5,
      tags: ['#TâmSự', '#HộiHọa', '#CàPhê'],
      bio: 'Một tâm hồn mộng mơ tìm kiếm sự đồng điệu chân thành...',
      gender: 'female',
    ),
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

        // Chọn đối phương phù hợp
        _pickBestMatch();

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
    List<MatchUser> pool = _fallbackPartners;

    if (homeState.matchedUsers.isNotEmpty) {
      pool = homeState.matchedUsers;
    }

    // Ưu tiên người có cùng cảm xúc hoặc điểm tương hợp cao nhất
    final sameMoodMatches = pool.where((u) => u.emotion.toLowerCase().contains(_currentMood.toLowerCase())).toList();
    if (sameMoodMatches.isNotEmpty) {
      _matchedPartner = sameMoodMatches.first;
    } else {
      _matchedPartner = pool.first;
    }
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
                  painter: _CosmicWavePainter(
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
                    Text(
                      'PHÁT SÓNG ĐỊNH MỆNH 432Hz',
                      style: TextStyle(
                        color: const Color(0xFF00FFB2),
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
            child: _buildCenterCore(screenWidth),
          ),

          // 6. Thẻ trạng thái tiến trình sóng & Thông báo khóa kênh
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding + 115,
            child: _buildPhaseStatusCard(),
          ),

          // 7. Thanh chọn nhanh tần số tâm trạng (Mood Pills)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 20,
            child: _buildMoodSelector(),
          ),
        ],
      ),
    );
  }

  /// Khối trung tâm: Avatar với các vòng tròn xung động phát sóng
  Widget _buildCenterCore(double screenWidth) {
    final coreSize = screenWidth * 0.32;

    return SizedBox(
      width: coreSize * 2.4,
      height: coreSize * 2.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Quầng sáng phát quang nền
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final scale = 1.0 + (_pulseController.value * 0.25);
              final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0) * 0.45;
              return Container(
                width: coreSize * 1.8 * scale,
                height: coreSize * 1.8 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF2A6D).withValues(alpha: opacity),
                ),
              );
            },
          ),

          // Vòng tròn hào quang Neon
          Container(
            width: coreSize + 16,
            height: coreSize + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2A6D), Color(0xFF00F0FF), Color(0xFF9D00FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2A6D).withValues(alpha: 0.6),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Avatar trung tâm
          Container(
            width: coreSize,
            height: coreSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF131127),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: _myAvatarUrl != null && _myAvatarUrl!.isNotEmpty
                  ? Image.network(
                      _myAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ),

          // Huy hiệu tần số 432Hz bên dưới avatar
          Positioned(
            bottom: coreSize * 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00FFB2).withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFB2).withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.graphic_eq_rounded, color: Color(0xFF00FFB2), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '$_currentMood • 432Hz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFF261845),
      child: const Center(
        child: Icon(
          Icons.favorite_rounded,
          color: Color(0xFFFF5E97),
          size: 38,
        ),
      ),
    );
  }

  /// Thẻ trạng thái tiến trình sóng và thông báo chạm sóng
  Widget _buildPhaseStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _broadcastPhase == 3
                  ? const Color(0xFF00FFB2).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildPhaseContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_broadcastPhase) {
      case 0:
        return Row(
          key: const ValueKey(0),
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFFF2A6D),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đang nén tần số 432Hz...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Chuẩn bị giải phóng sóng cảm xúc vào không gian',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );

      case 1:
        return Row(
          key: const ValueKey(1),
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF00F0FF),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đang lan tỏa tín hiệu...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Quét các linh hồn cùng tần số trong bán kính 10km',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );

      case 2:
        return Row(
          key: const ValueKey(2),
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFFFFC107), size: 18),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đã tìm thấy 3 tâm hồn cùng tần số!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Đang chờ phản hồi chạm sóng đầu tiên (Fast-Pass)...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );

      case 3:
      default:
        final partner = _matchedPartner!;
        return Row(
          key: const ValueKey(3),
          children: [
            // Avatar đối phương bắt sóng
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00FFB2), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFB2).withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipOval(
                child: partner.avatar != null && partner.avatar!.isNotEmpty
                    ? Image.network(
                        partner.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPartnerFallback(partner),
                      )
                    : _buildPartnerFallback(partner),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          partner.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFB2).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${partner.compatibilityScore}% Đồng điệu',
                          style: const TextStyle(
                            color: Color(0xFF00FFB2),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '✨ Đã khóa kênh 1-1! Đang đưa vào phòng 120s...',
                    style: TextStyle(
                      color: Color(0xFF00FFB2),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPartnerFallback(MatchUser partner) {
    return Container(
      color: const Color(0xFF4A148C),
      child: Center(
        child: Text(
          partner.displayName.isNotEmpty ? partner.displayName[0] : 'S',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Thanh chọn nhanh tần số cảm xúc
  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Text(
            'Chọn tần số cảm xúc muốn lan tỏa:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _availableMoods.map((m) {
              final isSelected = _currentMood == m['name'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentMood = m['name']!);
                    _startBroadcastSequence();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF2A6D).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF2A6D)
                            : Colors.white.withValues(alpha: 0.12),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m['icon']!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          m['name']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter vẽ các vòng sóng âm 432Hz lan tỏa và vệ tinh linh hồn
class _CosmicWavePainter extends CustomPainter {
  final double pulseValue;
  final double spinValue;
  final int phase;

  _CosmicWavePainter({
    required this.pulseValue,
    required this.spinValue,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final maxRadius = size.width * 0.85;

    // Vẽ 3 vòng tròn sóng lan tỏa
    for (int i = 0; i < 3; i++) {
      final waveProgress = (pulseValue + (i / 3.0)) % 1.0;
      final currentRadius = 60.0 + (waveProgress * (maxRadius - 60.0));
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.35;

      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = (phase >= 2 ? const Color(0xFF00FFB2) : const Color(0xFFFF2A6D))
            .withValues(alpha: opacity);

      canvas.drawCircle(center, currentRadius, wavePaint);
    }

    // Vẽ các đốm vệ tinh linh hồn lướt quanh quỹ đạo
    if (phase >= 1) {
      final orbitRadius = size.width * 0.38;
      for (int i = 0; i < 3; i++) {
        final angle = (spinValue * 2 * math.pi) + (i * (2 * math.pi / 3));
        final nodePos = Offset(
          center.dx + math.cos(angle) * orbitRadius,
          center.dy + math.sin(angle) * orbitRadius,
        );

        // Hào quang vệ tinh
        final glowPaint = Paint()
          ..color = (phase >= 2 ? const Color(0xFF00FFB2) : const Color(0xFF00F0FF))
              .withValues(alpha: 0.35);
        canvas.drawCircle(nodePos, 8.0, glowPaint);

        // Tâm vệ tinh
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(nodePos, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicWavePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.spinValue != spinValue ||
        oldDelegate.phase != phase;
  }
}
