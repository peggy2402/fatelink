import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Modal chọn ngày sinh phong cách Vũ trụ (Cosmic Date Picker)
/// Thay thế hoàn toàn Material DatePicker mặc định, mang lại trải nghiệm
/// chọn ngày sinh mượt mà, hiển thị Cung Hoàng Đạo & Tuổi theo thời gian thực.
class CosmicDatePickerModal extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CosmicDatePickerModal({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  /// Phương thức tĩnh mở Modal chọn ngày sinh
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final now = DateTime.now();
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CosmicDatePickerModal(
        initialDate: initialDate ?? DateTime(now.year - 20, 1, 1),
        firstDate: firstDate ?? DateTime(1940),
        lastDate: lastDate ?? DateTime(now.year - 14, now.month, now.day),
      ),
    );
  }

  @override
  State<CosmicDatePickerModal> createState() => _CosmicDatePickerModalState();
}

class _CosmicDatePickerModalState extends State<CosmicDatePickerModal> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  int get _calculatedAge {
    final now = DateTime.now();
    int age = now.year - _selectedDate.year;
    if (now.month < _selectedDate.month ||
        (now.month == _selectedDate.month && now.day < _selectedDate.day)) {
      age--;
    }
    return age;
  }

  Map<String, String> get _zodiacInfo {
    final day = _selectedDate.day;
    final month = _selectedDate.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return {'name': 'Bạch Dương ♈', 'element': 'Lửa 🔥', 'desc': 'Tiên phong, đam mê & nhiệt huyết'};
    }
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return {'name': 'Kim Ngưu ♉', 'element': 'Đất 🌿', 'desc': 'Chân thành, kiên định & ấm áp'};
    }
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return {'name': 'Song Tử ♊', 'element': 'Khí 💨', 'desc': 'Linh hoạt, thông tuệ & lôi cuốn'};
    }
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return {'name': 'Cự Giải ♋', 'element': 'Nước 🌊', 'desc': 'Sâu lắng, quan tâm & giàu cảm xúc'};
    }
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return {'name': 'Sư Tử ♌', 'element': 'Lửa 🔥', 'desc': 'Tự tin, rực rỡ & ấm áp chân thành'};
    }
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return {'name': 'Xử Nữ ♍', 'element': 'Đất 🌿', 'desc': 'Tinh tế, tỉ mỉ & đáng tin cậy'};
    }
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return {'name': 'Thiên Bình ♎', 'element': 'Khí 💨', 'desc': 'Hài hòa, thanh lịch & thấu hiểu'};
    }
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return {'name': 'Bọ Cạp ♏', 'element': 'Nước 🌊', 'desc': 'Bí ẩn, sâu sắc & mãnh liệt'};
    }
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return {'name': 'Nhân Mã ♐', 'element': 'Lửa 🔥', 'desc': 'Tự do, lạc quan & phóng khoáng'};
    }
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return {'name': 'Ma Kết ♑', 'element': 'Đất 🌿', 'desc': 'Bản lĩnh, kiên trì & đáng tin cậy'};
    }
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return {'name': 'Bảo Bình ♒', 'element': 'Khí 💨', 'desc': 'Độc đáo, sáng tạo & đồng điệu'};
    }
    return {'name': 'Song Ngư ♓', 'element': 'Nước 🌊', 'desc': 'Lãng mạn, vị tha & trực giác nhạy bén'};
  }

  @override
  Widget build(BuildContext context) {
    final zodiac = _zodiacInfo;
    final age = _calculatedAge;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F6366F1),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo mượt
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề & Icon Chiêm tinh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ngày sinh & Cung Hoàng Đạo',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tọa độ thời gian kiến tạo nên tần số của bạn',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12.5,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cake_rounded, color: Color(0xFF6366F1), size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Huy hiệu Cung Hoàng Đạo & Tuổi thời gian thực
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDF2F8), Color(0xFFEEF2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E7FF)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$age tuổi',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              zodiac['name']!,
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFC7D2FE)),
                              ),
                              child: Text(
                                zodiac['element']!,
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          zodiac['desc']!,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bánh xe cuộn chọn ngày tháng năm kiểu Apple Cupertino mượt mà
            SizedBox(
              height: 190,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: widget.firstDate,
                maximumDate: widget.lastDate,
                dateOrder: DatePickerDateOrder.dmy,
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Nút Xác nhận đồng điệu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedDate);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Xác nhận ngày sinh ✨',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
    );
  }
}
