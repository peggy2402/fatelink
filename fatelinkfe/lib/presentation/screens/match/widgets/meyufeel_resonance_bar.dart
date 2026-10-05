import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thanh hiển thị tiến trình "MeyuFeel" & Chuỗi ngọn lửa tinh vân "MeyuFlame"
/// - Luôn bắt đầu từ 0% khi mới bắt đầu trò chuyện.
/// - Đạt các cột mốc: 20%, 40%, 60%, 80%, 100%.
/// - Triết lý: "Cảm xúc có thể thay đổi bất kỳ lúc nào, nhưng Tính cách sẽ theo ta mãi mãi".
/// - Bông hoa tím lung linh MeyuFeel Crystal Lotus xuất hiện ở giữa màn hình.
/// - Ngọn lửa MeyuFlame: Phong cách tinh thể vũ trụ tím-hồng-lam, độc bản không trùng lặp TikTok.
/// - Background trong suốt, thanh thoát, không viền hộp thô.
class MeyuFeelResonanceBar extends StatelessWidget {
  final int streakDays;
  final int messageCount;
  final String partnerName;
  final String frequencyHertz;

  const MeyuFeelResonanceBar({
    super.key,
    this.streakDays = 1,
    required this.messageCount,
    required this.partnerName,
    this.frequencyHertz = '528 Hz',
  });

  /// Tính phần trăm MeyuFeel bắt đầu chính xác từ 0%
  /// Càng trò chuyện chân thành, chỉ số càng tăng trưởng thực chất
  int get meyuFeelPercent {
    // 0 tin nhắn = 0%
    if (messageCount <= 1) return 0;
    // Mỗi tin nhắn tương tác tăng ~3% cho đến 100%
    final calculated = ((messageCount - 1) * 3).clamp(0, 100);
    return calculated;
  }

  /// 5 Cột mốc tiến hóa thấu hiểu
  String get meyuFeelStage {
    final pct = meyuFeelPercent;
    if (pct >= 100) return 'MeyuFeel Vĩnh Cửu';
    if (pct >= 80) return 'Gắn kết tính cách cốt lõi';
    if (pct >= 60) return 'Tri âm thấu cảm sâu sắc';
    if (pct >= 40) return 'Đồng điệu cảm xúc';
    if (pct >= 20) return 'Nụ mầm tinh tú hé nở';
    return 'Giao thoa sơ khởi';
  }

  /// Mô tả chi tiết cho từng giai đoạn
  String get meyuFeelDescription {
    final pct = meyuFeelPercent;
    if (pct >= 100) {
      return 'Cảm xúc thăng hoa và Tính cách hòa làm một. Hai bạn đã đạt đến cảnh giới tri âm thấu hiểu toàn diện nhất! ✨';
    }
    if (pct >= 80) {
      return 'Cảm xúc có thể dao động theo từng ngày, nhưng tính cách chính là bản ngã đồng hành mãi mãi. Hai bạn đã thấu rõ cốt cách của nhau.';
    }
    if (pct >= 60) {
      return 'Những câu chuyện dài bắt đầu mở ra thế giới nội tâm sâu kín và những sở thích tương đồng.';
    }
    if (pct >= 40) {
      return 'Hai bạn đã bắt đầu cảm nhận được năng lượng và tâm trạng của đối phương qua từng dòng tin.';
    }
    if (pct >= 20) {
      return 'Nụ hoa tím MeyuFeel bắt đầu nảy mầm từ những câu chào chân thành đầu tiên.';
    }
    return 'Hai người vừa mới ghép đôi thành công. Hãy bắt đầu gửi những tin nhắn đầu tiên để kích hoạt hành trình thấu hiểu từ 0% nhé!';
  }

  /// Hiển thị Modal Bản Đồ MeyuFeel với Bông hoa tím lung linh giữa màn hình
  void _showMeyuFeelDetailModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0B1E), // Nền không gian vũ trụ huyền ảo
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Color(0x66A855F7),
                blurRadius: 36,
                offset: Offset(0, -10),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh kéo
                Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),

                // Huy hiệu MeyuFlame (Lửa tinh vân vũ trụ độc bản)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9333EA).withValues(alpha: 0.35),
                        const Color(0xFFEC4899).withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Biểu tượng ngọn lửa tinh thể MeyuFlame
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFF472B6), Color(0xFFA855F7), Color(0xFF38BDF8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MeyuFlame • $streakDays ngày kết nối',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF472B6),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tiêu đề & Cấp độ
                Text(
                  'Chỉ số thấu hiểu MeyuFeel',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'với $partnerName • $meyuFeelPercent% Đồng điệu',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC084FC),
                  ),
                ),
                const SizedBox(height: 20),

                // BÔNG HOA TÍM LUNG LINH Ở GIỮA MÀN HÌNH (MeyuFeel Crystal Lotus)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hào quang phát sáng tỏa tròn (Radial Glow)
                      Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.45),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      // Bông hoa pha lê tím vũ trụ
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE9D5FF).withValues(alpha: 0.6),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/meyufeel_crystal_lotus.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: const Color(0xFF2E1065),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFC084FC),
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Badge cấp độ hoa đính kèm
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            meyuFeelStage,
                            style: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 5 Cột mốc cấp độ (20% -> 40% -> 60% -> 80% -> 100%)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cột mốc nở hoa MeyuFeel',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          Text(
                            '$meyuFeelPercent / 100%',
                            style: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF472B6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: meyuFeelPercent / 100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC084FC)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMilestoneDot('20%', 'Nụ mầm', meyuFeelPercent >= 20),
                          _buildMilestoneDot('40%', 'Cảm xúc', meyuFeelPercent >= 40),
                          _buildMilestoneDot('60%', 'Tri âm', meyuFeelPercent >= 60),
                          _buildMilestoneDot('80%', 'Tính cách', meyuFeelPercent >= 80),
                          _buildMilestoneDot('100%', 'Vĩnh kết', meyuFeelPercent >= 100),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Triết lý Cảm xúc & Tính cách
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B0764).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🪷', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          meyuFeelDescription,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nút Đóng
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cùng thấu hiểu nhiều hơn',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneDot(String label, String sub, bool isUnlocked) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked ? const Color(0xFFC084FC) : Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: isUnlocked ? Colors.white : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              isUnlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
              size: 12,
              color: isUnlocked ? Colors.white : Colors.white54,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 10.5,
            fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
            color: isUnlocked ? const Color(0xFFE9D5FF) : Colors.white38,
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 9.5,
            color: isUnlocked ? const Color(0xFFF472B6) : Colors.white24,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Giao diện thanh thoát: Ẩn background container trắng đục, hòa vào nền màn hình
    return GestureDetector(
      onTap: () => _showMeyuFeelDetailModal(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            // Ngọn lửa MeyuFlame (Gradient tím hồng ánh lam độc bản)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFAF5FF), Color(0xFFFDF2F8)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3E8FF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streakDays',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Tiến trình MeyuFeel (Bắt đầu từ 0%)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'MeyuFeel: $meyuFeelStage',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$meyuFeelPercent%',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: meyuFeelPercent / 100,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
