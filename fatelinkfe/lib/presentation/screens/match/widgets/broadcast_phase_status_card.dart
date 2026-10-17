import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../data/models/match_user.dart';

class BroadcastPhaseStatusCard extends StatelessWidget {
  final int broadcastPhase;
  final String currentMood;
  final String frequency;
  final MatchUser? matchedPartner;
  final int matchedCount;

  const BroadcastPhaseStatusCard({
    super.key,
    required this.broadcastPhase,
    required this.currentMood,
    required this.frequency,
    this.matchedPartner,
    required this.matchedCount,
  });

  Widget _buildPartnerFallback(MatchUser partner) {
    return Container(
      color: const Color(0xFF4A148C),
      child: Center(
        child: Text(
          partner.displayName.isNotEmpty ? partner.displayName[0] : 'S',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (broadcastPhase) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đang nén tần số $frequency...',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Chuẩn bị giải phóng sóng cảm xúc vào không gian',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 1:
        return const Row(
          key: ValueKey(1),
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF00F0FF),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đang lan tỏa tín hiệu...',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Quét các linh hồn cùng tần số trong bán kính 10km',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 2:
        final phase2Title = matchedCount > 0
            ? 'Đã tìm thấy $matchedCount tâm hồn cùng tần số!'
            : 'Đang mở rộng phạm vi quét tần số...';
        final phase2Sub = matchedCount > 0
            ? 'Đang chờ phản hồi chạm sóng đầu tiên (Fast-Pass)...'
            : 'Chưa có tâm hồn nào trực tuyến cùng tần số. Giữ sóng để kết nối sớm nhất!';

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
              child: const Icon(
                Icons.wifi_tethering_rounded,
                color: Color(0xFFFFC107),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phase2Title,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phase2Sub,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 3:
      default:
        final partner = matchedPartner;
        if (partner == null) return const SizedBox.shrink();

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
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPartnerFallback(partner),
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
                            fontFamily: 'BeVietnamPro',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFB2).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${partner.compatibilityScore}% Đồng điệu',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
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
                      fontFamily: 'BeVietnamPro',
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

  @override
  Widget build(BuildContext context) {
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
              color: broadcastPhase == 3
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
}
