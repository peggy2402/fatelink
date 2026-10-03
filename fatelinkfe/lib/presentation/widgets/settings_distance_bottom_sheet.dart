import 'package:flutter/material.dart';

class SettingsDistanceBottomSheet extends StatefulWidget {
  final String currentValue;
  const SettingsDistanceBottomSheet({super.key, required this.currentValue});

  @override
  State<SettingsDistanceBottomSheet> createState() =>
      _SettingsDistanceBottomSheetState();
}

class _SettingsDistanceBottomSheetState
    extends State<SettingsDistanceBottomSheet> {
  late String _selectedValue;
  final List<String> _options = [
    'Hiện khoảng cách chính xác',
    'Chỉ hiện khu vực',
    'Ẩn hoàn toàn',
  ];

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset > 0 ? 12 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thanh Drag Handle chuẩn iOS / Material 3
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  // Header Tiêu đề & Nút Đóng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hiển thị khoảng cách',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Danh sách các tùy chọn
                  ..._options.map((option) => _buildOptionRow(option)),

                  const SizedBox(height: 20),

                  // Nút Xác Nhận với Gradient Cosmic
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selectedValue),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow(String title) {
    final isSelected = _selectedValue == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedValue = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF4338CA)
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}