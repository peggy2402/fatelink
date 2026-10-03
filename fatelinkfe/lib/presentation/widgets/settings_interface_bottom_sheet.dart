import 'package:flutter/material.dart';

class SettingsInterfaceBottomSheet extends StatefulWidget {
  final String currentValue;
  const SettingsInterfaceBottomSheet({super.key, required this.currentValue});

  @override
  State<SettingsInterfaceBottomSheet> createState() =>
      _SettingsInterfaceBottomSheetState();
}

class _SettingsInterfaceBottomSheetState
    extends State<SettingsInterfaceBottomSheet> {
  late String _selectedValue;

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
                  // Thanh Drag Handle
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
                        'Chủ đề giao diện',
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
                  const SizedBox(height: 16),

                  // 3 Card lựa chọn giao diện trực quan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageOption('Sáng', Icons.light_mode_rounded, 'Nền sáng'),
                      _buildImageOption('Tối', Icons.dark_mode_rounded, 'Cosmic Dark'),
                      _buildImageOption('Hệ thống', Icons.settings_system_daydream_rounded, 'Tự động'),
                    ],
                  ),
                  const SizedBox(height: 24),

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

  Widget _buildImageOption(String title, IconData icon, String subtitle) {
    final isSelected = _selectedValue == title;

    return GestureDetector(
      onTap: () => setState(() => _selectedValue = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}