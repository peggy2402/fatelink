import 'package:flutter/material.dart';

class ProfilePersonalityChart extends StatelessWidget {
  final Map<String, dynamic>? emotions;

  const ProfilePersonalityChart({
    super.key,
    this.emotions,
  });

  @override
  Widget build(BuildContext context) {
    final double calmness =
        ((emotions?['calmness'] ?? 7) as num).toDouble() / 10.0;
    final double warmth = ((emotions?['warmth'] ?? 8) as num).toDouble() / 10.0;
    final double depth =
        ((emotions?['loneliness'] ?? 6) as num).toDouble() / 10.0;
    final double positive =
        ((emotions?['happiness'] ?? 7) as num).toDouble() / 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF8B5CF6),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Chiều sâu tâm lý (AI Emotion Vector)',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressItem(
            'Ấm áp & Chân thành',
            warmth,
            const Color(0xFFEC4899),
            const Color(0xFFFCE7F3),
          ),
          _buildProgressItem(
            'Bình yên nội tâm',
            calmness,
            const Color(0xFF10B981),
            const Color(0xFFD1FAE5),
          ),
          _buildProgressItem(
            'Chiều sâu tâm tư',
            depth,
            const Color(0xFF6366F1),
            const Color(0xFFE0E7FF),
          ),
          _buildProgressItem(
            'Tần số tích cực',
            positive,
            const Color(0xFFF59E0B),
            const Color(0xFFFEF3C7),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String label,
    double value,
    Color mainColor,
    Color bgColor,
  ) {
    final percent = (value * 100).clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(mainColor),
            ),
          ),
        ],
      ),
    );
  }
}
