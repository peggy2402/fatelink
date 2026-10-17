import 'package:flutter/material.dart';

class EditProfileFrequencyCard extends StatelessWidget {
  final String selectedMoodIcon;
  final String selectedHertz;
  final String currentMoodTitle;
  final VoidCallback onScanRadar;

  const EditProfileFrequencyCard({
    super.key,
    required this.selectedMoodIcon,
    required this.selectedHertz,
    required this.currentMoodTitle,
    required this.onScanRadar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tần số cảm xúc hiện tại',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$selectedMoodIcon $selectedHertz',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Đang phát: $currentMoodTitle',
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tần số tâm hồn được hệ thống đo lường khách quan từ Trợ lý AI Faye và Radar 3 chạm theo thời gian thực (không phải cấu hình ngẫu nhiên).',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Nút quét lại tần số
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onScanRadar,
              icon: const Icon(
                Icons.radar_rounded,
                color: Color(0xFF6366F1),
                size: 18,
              ),
              label: const Flexible(
                child: Text(
                  'Quét lại tần số tâm trạng (Radar 3 chạm)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.2),
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
