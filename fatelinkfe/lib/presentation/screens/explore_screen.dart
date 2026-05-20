import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

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
          
          // 5. Orbiting Nodes (Other Profiles)
          // These positions are for demonstration. In a real app, they'd be calculated.
          _FloatingNode(
            initialTop: MediaQuery.of(context).size.height * 0.25,
            initialLeft: MediaQuery.of(context).size.width * 0.1,
            userName: 'Jessica',
            compatibility: 95,
            avatarUrl: 'assets/images/default_avatar.png', // Placeholder
            animationDelay: const Duration(milliseconds: 500),
            onTap: () => _showMiniProfile(context),
          ),
          _FloatingNode(
            initialTop: MediaQuery.of(context).size.height * 0.35,
            initialLeft: MediaQuery.of(context).size.width * 0.7,
            userName: 'David',
            compatibility: 88,
            avatarUrl: 'assets/images/default_avatar.png', // Placeholder
            animationDelay: const Duration(milliseconds: 0),
            onTap: () => _showMiniProfile(context),
          ),
          _FloatingNode(
            initialTop: MediaQuery.of(context).size.height * 0.6,
            initialLeft: MediaQuery.of(context).size.width * 0.2,
            userName: 'Chloe',
            compatibility: 91,
            avatarUrl: 'assets/images/default_avatar.png', // Placeholder
            animationDelay: const Duration(milliseconds: 800),
            onTap: () => _showMiniProfile(context),
          ),
        ],
      ),
    );
  }

  void _showMiniProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MiniProfileSheet(),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // This color is masked
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Những tần số đang ở gần bạn',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              Container(
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

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
            child: const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/images/default_avatar.png'),
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
                      backgroundImage: AssetImage(widget.avatarUrl),
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
              Text(
                widget.userName,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Mini Profile Bottom Sheet Widget
class _MiniProfileSheet extends StatelessWidget {
  const _MiniProfileSheet();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.transparent,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(top: BorderSide(color: Colors.white, width: 1.5)),
                  ),
                  child: Stack(
                    children: [
                      ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(24),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/images/default_avatar.png', // Placeholder
                                  width: 120,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 180,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jessica, 24',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tần số: 95% tương hợp',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.pink.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(25),
                                              gradient: const LinearGradient(
                                                colors: [Colors.pinkAccent, Colors.orangeAccent],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.pink.withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                )
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: () {},
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                              ),
                                              child: const Text(
                                                'Làm quen',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                              )
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.favorite_border, color: Colors.pink.shade300),
                                            onPressed: () {},
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Add more profile details here
                          const SizedBox(height: 24),
                          const Text('Giới thiệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text('Thích đi dạo bờ hồ, nghe nhạc Lofi và những buổi chiều mưa. Tìm một người có thể cùng nhau im lặng mà không thấy ngượng ngùng.', style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                        ],
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.1),
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}