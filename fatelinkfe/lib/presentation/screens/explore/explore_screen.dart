import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fatelinkfe/core/responsive/responsive.dart';
import 'package:fatelinkfe/logic/blocs/home/home_bloc.dart';
import 'package:fatelinkfe/logic/blocs/home/home_state.dart';
import 'package:fatelinkfe/presentation/screens/profile/user_detail_screen.dart';

// Main Screen Widget
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade50,
                  Colors.white,
                  Colors.pink.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Radar Background Animation
          const _RadarBackground(),

          // 3. Header
          const _Header(),

          // 4. Center Node (Current User)
          const _CenterNode(),
          
          // 5. Orbiting Nodes (Real Matched Profiles from HomeBloc)
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              final users = state.matchedUsers;
              if (users.isEmpty) {
                return Positioned(
                  bottom: 110,
                  left: 24,
                  right: 24,
                  child: ResponsiveCenter(
                    maxWidth: 460,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radar_rounded, color: Color(0xFF6366F1), size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Đang phát sóng & quét tìm tâm hồn đồng điệu...',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final screenWidth = context.screenWidth;
              final screenHeight = context.screenHeight;
              final centerX = screenWidth / 2;
              final centerY = screenHeight * 0.48;
              final maxRadius = math.min(screenWidth, screenHeight) * 0.36;

              final angles = [-0.75, 0.65, 2.35, -2.25];
              final distMultipliers = [0.82, 0.94, 0.76, 0.88];

              return Stack(
                children: users.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  final angle = angles[index % angles.length];
                  final dist = distMultipliers[index % distMultipliers.length] * maxRadius;
                  final posX = (centerX + dist * math.cos(angle) - 35).clamp(16.0, screenWidth - 86.0);
                  final posY = (centerY + dist * math.sin(angle) - 35).clamp(80.0, screenHeight - 160.0);

                  return _FloatingNode(
                    key: ValueKey(user.id),
                    initialTop: posY,
                    initialLeft: posX,
                    userName: user.name,
                    compatibility: user.compatibilityScore,
                    avatarUrl: user.avatar ?? '',
                    animationDelay: Duration(milliseconds: index * 400),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserDetailScreen(user: user),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Header Widget
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.pinkAccent, Colors.orangeAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Khám phá',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // This color is masked
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Những tần số đang ở gần bạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list_rounded, color: Colors.black54),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Radar Background Animation Widget
class _RadarBackground extends StatefulWidget {
  const _RadarBackground();

  @override
  State<_RadarBackground> createState() => _RadarBackgroundState();
}

class _RadarBackgroundState extends State<_RadarBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(4, (index) {
              final double progress = (_controller.value + (index * 0.25)) % 1.0;
              final double scale = 1.5 * progress;
              final double opacity = (1.0 - progress) * 0.3;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.indigo.shade100.withOpacity(opacity),
                      width: 2.0,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// Center Node (Current User) Widget
class _CenterNode extends StatefulWidget {
  const _CenterNode();

  @override
  State<_CenterNode> createState() => _CenterNodeState();
}

class _CenterNodeState extends State<_CenterNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pingController;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    const secureStorage = FlutterSecureStorage();
    final avatar = await secureStorage.read(key: 'avatarUrl');
    if (mounted && avatar != null) {
      setState(() => _avatarUrl = avatar);
    }
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ping/Ripple Animation
          AnimatedBuilder(
            animation: _pingController,
            builder: (context, child) {
              final double progress = _pingController.value;
              final double scale = 1.0 + progress * 1.5;
              final double opacity = 1.0 - progress;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(opacity * 0.5),
                  ),
                ),
              );
            },
          ),
          // User Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFE0E7FF),
              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                  ? NetworkImage(_avatarUrl!) as ImageProvider
                  : const AssetImage('assets/images/default_avatar.png'),
            ),
          ),
        ],
      ),
    );
  }
}

// Floating/Orbiting Node Widget
class _FloatingNode extends StatefulWidget {
  final double initialTop;
  final double initialLeft;
  final String userName;
  final int compatibility;
  final String avatarUrl;
  final Duration animationDelay;
  final VoidCallback onTap;

  const _FloatingNode({
    super.key,
    required this.initialTop,
    required this.initialLeft,
    required this.userName,
    required this.compatibility,
    required this.avatarUrl,
    required this.animationDelay,
    required this.onTap,
  });

  @override
  State<_FloatingNode> createState() => _FloatingNodeState();
}

class _FloatingNodeState extends State<_FloatingNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    Timer(widget.animationDelay, () {
      if (mounted) {
        _floatController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.initialTop,
      left: widget.initialLeft,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            );
          },
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, Colors.cyanAccent],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFE0E7FF),
                      backgroundImage: (widget.avatarUrl.isNotEmpty && widget.avatarUrl.startsWith('http'))
                          ? NetworkImage(widget.avatarUrl) as ImageProvider
                          : AssetImage(widget.avatarUrl.isNotEmpty ? widget.avatarUrl : 'assets/images/default_avatar.png'),
                      onBackgroundImageError: (_, __) {}, // Handle error
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                          )
                        ],
                      ),
                      child: Text(
                        '${widget.compatibility}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 80,
                child: Text(
                  widget.userName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}