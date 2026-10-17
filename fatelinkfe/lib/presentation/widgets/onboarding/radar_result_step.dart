import 'dart:async';
import 'package:flutter/material.dart';
import 'radar_pulse_animation.dart';

class RadarResultStep extends StatefulWidget {
  final String mood;
  final String vibe;
  final String signal;
  final VoidCallback onExploreMatches;
  final VoidCallback onChatWithFaye;

  const RadarResultStep({
    super.key,
    required this.mood,
    required this.vibe,
    required this.signal,
    required this.onExploreMatches,
    required this.onChatWithFaye,
  });

  @override
  State<RadarResultStep> createState() => _RadarResultStepState();
}

class _RadarResultStepState extends State<RadarResultStep> {
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    // Simulate high-tech radar analysis for 1.5 seconds
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    });
  }

  String _calculateHertz() {
    if (widget.mood.contains('Deep')) return '528 Hz';
    if (widget.mood.contains('Chill')) return '432 Hz';
    if (widget.mood.contains('Hứng')) return '741 Hz';
    return '639 Hz';
  }

  String _calculateFrequencyTitle() {
    if (widget.mood.contains('Deep')) return 'Tần số Chữa Lành & Bình Yên';
    if (widget.mood.contains('Chill')) return 'Tần số Cân Bằng & Thư Thái';
    if (widget.mood.contains('Hứng')) return 'Tần số Tự Do & Rực Rỡ';
    return 'Tần số Kết Nối Tâm Giao';
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadarPulseAnimation(
              size: 110,
              centerChild: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFF43F5E),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icon/app_logo.png',
                    width: 52,
                    height: 52,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đang kích hoạt Radar Meyu...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang đối soát bước sóng tâm hồn trong bán kính gần bạn...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                color: Color(0xFFF43F5E),
                backgroundColor: Colors.white12,
                minHeight: 3,
              ),
            ),
          ],
        ),
      );
    }

    final hertz = _calculateHertz();
    final title = _calculateFrequencyTitle();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        // Glowing 3D Heart with Pulse
        Center(
          child: RadarPulseAnimation(
            size: 90,
            centerChild: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/icon/app_logo.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Success Pill
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
                SizedBox(width: 6),
                Text(
                  'ĐÃ ĐO THÀNH CÔNG BƯỚC SÓNG',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Hertz & Title
        Text(
          hertz,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFB7185),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),

        // Selected tags preview
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildTag(widget.mood),
            _buildTag(widget.vibe),
            _buildTag(widget.signal),
          ],
        ),
        const SizedBox(height: 16),

        // Match Found Notification Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E), size: 18),
              SizedBox(width: 8),
              Text(
                'Phát hiện 12 người cùng tần số gần bạn!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Primary Action: Explore Matches
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: widget.onExploreMatches,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Khám phá người cùng tần số ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Secondary Action: Nâng cấp trải nghiệm thấu cảm cùng Faye AI
        Container(
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onChatWithFaye,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Để Faye hiểu sâu hơn về bạn',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.auto_awesome_rounded, color: Color(0xFF00E5FF), size: 13),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Trò chuyện tự nhiên để Faye hiệu chuẩn tần số chuẩn xác hơn',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              color: Color(0xFF94A3B8),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 13),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '#$text',
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
