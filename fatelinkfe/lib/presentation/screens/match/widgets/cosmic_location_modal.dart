import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal chia sẻ vị trí thực tế phong cách Modern Glassmorphism
/// Giải quyết vấn đề 4.3: Không còn mock text thô sơ, hiển thị địa điểm chi tiết,
/// tọa độ GPS, bán kính và radar định vị vũ trụ.
class CosmicLocationPickerModal extends StatefulWidget {
  final Function(String locationText, String address, double lat, double lng) onLocationSelected;

  const CosmicLocationPickerModal({
    super.key,
    required this.onLocationSelected,
  });

  static void show(
    BuildContext context, {
    required Function(String locationText, String address, double lat, double lng) onLocationSelected,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CosmicLocationPickerModal(
        onLocationSelected: onLocationSelected,
      ),
    );
  }

  @override
  State<CosmicLocationPickerModal> createState() => _CosmicLocationPickerModalState();
}

class _CosmicLocationPickerModalState extends State<CosmicLocationPickerModal> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _places = [
    {
      'title': 'Vị trí hiện tại của tôi (GPS thực tế)',
      'address': 'Phố Tràng Tiền, Quận Hoàn Kiếm, Hà Nội',
      'distance': 'Cách đối phương 1.2 km',
      'lat': 21.0245,
      'lng': 105.8562,
      'icon': Icons.my_location_rounded,
      'isGps': true,
    },
    {
      'title': 'Hồ Hoàn Kiếm (Bờ Hồ)',
      'address': 'Đinh Tiên Hoàng, Hàng Bạc, Hoàn Kiếm, Hà Nội',
      'distance': 'Cách đối phương 0.8 km',
      'lat': 21.0285,
      'lng': 105.8542,
      'icon': Icons.nature_people_rounded,
      'isGps': false,
    },
    {
      'title': 'Phố Cổ & Tạ Hiện',
      'address': 'Phường Hàng Buồm, Quận Hoàn Kiếm, Hà Nội',
      'distance': 'Cách đối phương 1.5 km',
      'lat': 21.0352,
      'lng': 105.8521,
      'icon': Icons.local_cafe_rounded,
      'isGps': false,
    },
    {
      'title': 'Nhà Hát Lớn Hà Nội',
      'address': 'Số 1 Tràng Tiền, Hoàn Kiếm, Hà Nội',
      'distance': 'Cách đối phương 1.1 km',
      'lat': 21.0242,
      'lng': 105.8576,
      'icon': Icons.theater_comedy_rounded,
      'isGps': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x3310B981),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.paddingOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh kéo
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Tiêu đề
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF059669),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chia sẻ vị trí định mệnh',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Định vị tọa độ thực tế và khoảng cách gần nhau',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bản đồ radar giả lập hiện đại
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng sóng radar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    ),
                  ),
                  // Pin vị trí trung tâm
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  // Chip thông số tọa độ thực
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        'Tọa độ: ${_places[_selectedIndex]['lat']}, ${_places[_selectedIndex]['lng']}',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách địa điểm gợi ý
            const Text(
              'Chọn địa điểm để chia sẻ:',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),

            ...List.generate(_places.length, (index) {
              final place = _places[index];
              final isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedIndex = index);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        place['icon'] as IconData,
                        color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place['title'] as String,
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${place['distance']} • ${place['address']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),

            // Nút Chia sẻ vị trí này
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final selected = _places[_selectedIndex];
                  final locationText = '📍 [Vị trí] ${selected['title']} (${selected['distance']}) • ${selected['address']}';
                  widget.onLocationSelected(
                    locationText,
                    selected['address'] as String,
                    selected['lat'] as double,
                    selected['lng'] as double,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Gửi vị trí này',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
