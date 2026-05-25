import 'package:flutter/material.dart';

class SettingsInterfaceBottomSheet extends StatefulWidget {
  final String currentValue;
  const SettingsInterfaceBottomSheet({super.key, required this.currentValue});

  @override
  State<SettingsInterfaceBottomSheet> createState() => _SettingsInterfaceBottomSheetState();
}

class _SettingsInterfaceBottomSheetState extends State<SettingsInterfaceBottomSheet> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header có nút Đóng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giao diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Content: 3 Hình ảnh trên 1 hàng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildImageOption('Sáng', Icons.light_mode_rounded),
              _buildImageOption('Tối', Icons.dark_mode_rounded),
              _buildImageOption('Hệ thống', Icons.settings_system_daydream_rounded),
            ],
          ),
          const SizedBox(height: 32),
          
          // Nút Xác Nhận
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Xác nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOption(String title, IconData mockIcon) {
    final isSelected = _selectedValue == title;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedValue = title),
      child: Column(
        children: [
          // Khung giả lập Ảnh (Bạn có thể thay Container này bằng Image.asset)
          Container(
            width: 86,
            height: 130,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF2FF) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(child: Icon(mockIcon, size: 40, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade400)),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          // Nút Checkbox Tròn
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade400, width: 2),
              color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
            ),
            child: isSelected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
        ],
      ),
    );
  }
}