import 'package:flutter/material.dart';
import '../../../../data/models/match_filter_criteria.dart';
import '../../../../data/models/match_user.dart';

class SoulFilterModal extends StatefulWidget {
  final MatchFilterCriteria initialCriteria;
  final List<MatchUser> allUsers;
  final ValueChanged<MatchFilterCriteria> onApply;

  const SoulFilterModal({
    super.key,
    required this.initialCriteria,
    required this.allUsers,
    required this.onApply,
  });

  /// Phương thức static tiện lợi để mở modal từ bất kỳ đâu
  static Future<MatchFilterCriteria?> show(
    BuildContext context, {
    required MatchFilterCriteria initialCriteria,
    required List<MatchUser> allUsers,
    required ValueChanged<MatchFilterCriteria> onApply,
  }) {
    return showModalBottomSheet<MatchFilterCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SoulFilterModal(
        initialCriteria: initialCriteria,
        allUsers: allUsers,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SoulFilterModal> createState() => _SoulFilterModalState();
}

class _SoulFilterModalState extends State<SoulFilterModal> {
  late MatchFilterCriteria _criteria;

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
  }

  void _resetFilter() {
    setState(() {
      _criteria = const MatchFilterCriteria();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán số lượng người khớp với bộ lọc theo thời gian thực
    final matchingUsers = _criteria.apply(widget.allUsers);
    final count = matchingUsers.length;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom +
        16;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x250F172A),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Thanh kéo (Handle bar) & Tiêu đề
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Bộ lọc kết nối',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _resetFilter,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 2. Nội dung các tùy chọn lọc
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // --- A. Giới tính ---
                _buildSectionTitle('Giới tính kết nối'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildGenderChip('all', 'Tất cả', Icons.all_inclusive_rounded),
                    const SizedBox(width: 10),
                    _buildGenderChip('female', 'Nữ', Icons.female_rounded),
                    const SizedBox(width: 10),
                    _buildGenderChip('male', 'Nam', Icons.male_rounded),
                  ],
                ),

                const SizedBox(height: 24),

                // --- B. Độ tuổi ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Độ tuổi'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_criteria.ageRange.start.round()} - ${_criteria.ageRange.end.round()} tuổi',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEC4899),
                        ),
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _criteria.ageRange,
                  min: 18,
                  max: 45,
                  divisions: 27,
                  activeColor: const Color(0xFF6366F1),
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (newRange) {
                    setState(() {
                      _criteria = _criteria.copyWith(ageRange: newRange);
                    });
                  },
                ),
                // Phím tắt chọn nhanh độ tuổi
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAgePresetChip('18 - 22', const RangeValues(18, 22)),
                      const SizedBox(width: 8),
                      _buildAgePresetChip('23 - 28', const RangeValues(23, 28)),
                      const SizedBox(width: 8),
                      _buildAgePresetChip('29 - 35', const RangeValues(29, 35)),
                      const SizedBox(width: 8),
                      _buildAgePresetChip('Tất cả (18 - 45+)', const RangeValues(18, 45)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- C. Khu vực & Cự ly ---
                _buildSectionTitle('Khu vực & Khoảng cách'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLocationChip('all', 'Toàn quốc', Icons.public_rounded),
                    _buildLocationChip('nearby', 'Gần bạn (< 5km)', Icons.near_me_rounded),
                    _buildLocationChip('city', 'Trong thành phố (< 25km)', Icons.location_city_rounded),
                    _buildLocationChip('custom', 'Tùy chỉnh bán kính', Icons.radar_rounded),
                  ],
                ),
                if (_criteria.locationScope == 'custom') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bán kính tối đa:',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${_criteria.maxDistanceKm.round()} km',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _criteria.maxDistanceKm,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: const Color(0xFF6366F1),
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (val) {
                      setState(() {
                        _criteria = _criteria.copyWith(maxDistanceKm: val);
                      });
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // --- D. Tần số cảm xúc ---
                _buildSectionTitle('Tần số cảm xúc đồng điệu'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildEmotionChip('all', 'Tất cả'),
                    _buildEmotionChip('Bình yên', '☕ Bình yên'),
                    _buildEmotionChip('Lạc quan', '✨ Lạc quan'),
                    _buildEmotionChip('Chill', '🎧 Chill đêm'),
                    _buildEmotionChip('Trầm lắng', '🌧️ Trầm lắng'),
                    _buildEmotionChip('Năng lượng', '🔥 Năng lượng'),
                  ],
                ),

                const SizedBox(height: 24),

                // --- E. Trạng thái online ---
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang phát sóng trực tuyến',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ưu tiên những tâm hồn đang online',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _criteria.onlineOnly,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          setState(() {
                            _criteria = _criteria.copyWith(onlineOnly: val);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Nút Áp dụng (Bottom CTA)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_criteria);
                  Navigator.of(context).pop(_criteria);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.35),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child: Text(
                      'Áp dụng ($count người phù hợp)',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildGenderChip(String genderKey, String label, IconData icon) {
    final isSelected = _criteria.gender == genderKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _criteria = _criteria.copyWith(gender: genderKey);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgePresetChip(String label, RangeValues range) {
    final isSelected = _criteria.ageRange.start.round() == range.start.round() &&
        _criteria.ageRange.end.round() == range.end.round();
    return GestureDetector(
      onTap: () {
        setState(() {
          _criteria = _criteria.copyWith(ageRange: range);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationChip(String scope, String label, IconData icon) {
    final isSelected = _criteria.locationScope == scope;
    return GestureDetector(
      onTap: () {
        setState(() {
          _criteria = _criteria.copyWith(locationScope: scope);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionChip(String emotionKey, String label) {
    final isSelected = (_criteria.emotion == emotionKey) ||
        (emotionKey == 'all' && (_criteria.emotion == null || _criteria.emotion == 'all'));
    return GestureDetector(
      onTap: () {
        setState(() {
          _criteria = _criteria.copyWith(emotion: emotionKey == 'all' ? null : emotionKey);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEC4899) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFEC4899) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
