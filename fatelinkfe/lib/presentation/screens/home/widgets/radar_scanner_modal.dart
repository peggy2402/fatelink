import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class RadarScannerModal extends StatefulWidget {
  final VoidCallback? onConnectMatch;

  const RadarScannerModal({super.key, this.onConnectMatch});

  static Future<void> show(BuildContext context, {VoidCallback? onConnectMatch}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RadarScannerModal(onConnectMatch: onConnectMatch),
    );
  }

  @override
  State<RadarScannerModal> createState() => _RadarScannerModalState();
}

class _RadarScannerModalState extends State<RadarScannerModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: math.max(MediaQuery.of(context).size.height * 0.75, 520.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.92), // Dark Slate
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radar Tâm Hồn 📡',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quét tần số đồng điệu trong bán kính 5km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --- Radar Visualization Screen ---
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Concentric Animated Ripple Waves
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _RadarWavePainter(
                            progress: _radarController.value,
                            color: const Color(0xFFEC4899),
                          ),
                          size: const Size(280, 280),
                        );
                      },
                    ),

                    // Discovered Soul Nodes
                    _buildSoulNode(
                      angle: -0.6,
                      distance: 90,
                      name: 'Jessica',
                      score: 95,
                      avatarSeed: 'Jessica',
                    ),
                    _buildSoulNode(
                      angle: 1.2,
                      distance: 110,
                      name: 'David',
                      score: 88,
                      avatarSeed: 'David',
                    ),
                    _buildSoulNode(
                      angle: 2.8,
                      distance: 80,
                      name: 'Chloe',
                      score: 92,
                      avatarSeed: 'Chloe',
                    ),

                    // Central User Pulse Node
                    Container(
                      width: 66,
                      height: 66,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF1E1B4B),
                        child: Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Result Action
              Padding(
                padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, bottomInset > 0 ? bottomInset + 12 : 24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFFEC4899), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Đã tìm thấy 3 tâm hồn có tần số tương hợp > 85%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onConnectMatch?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Xem tất cả định mệnh',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoulNode({
    required double angle,
    required double distance,
    required String name,
    required int score,
    required String avatarSeed,
  }) {
    final x = distance * math.cos(angle);
    final y = distance * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF6366F1)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://api.dicebear.com/7.x/adventurer/png?seed=$avatarSeed&backgroundColor=e0f7fa',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$score%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw fixed grid rings
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3), gridPaint);
    }

    // Draw scanning sweep/pulsing wave
    for (int i = 0; i < 3; i++) {
      final currentProgress = (progress + i / 3) % 1.0;
      final radius = currentProgress * maxRadius;
      final opacity = (1.0 - currentProgress).clamp(0.0, 1.0);

      final pulsePaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
