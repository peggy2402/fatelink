import 'package:flutter/material.dart';

class SettingsMatchBottomSheet extends StatefulWidget {
  final String currentValue;
  const SettingsMatchBottomSheet({super.key, required this.currentValue});

  @override
  State<SettingsMatchBottomSheet> createState() => _SettingsMatchBottomSheetState();
}

class _SettingsMatchBottomSheetState extends State<SettingsMatchBottomSheet> {
  late String _selectedValue;
  final List<String> _options = ['All', 'Nam', 'Nữ'];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giới tính ghép nối', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._options.map((option) => _buildOptionRow(option)),
          const SizedBox(height: 24),
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

  Widget _buildOptionRow(String title) {
    final isSelected = _selectedValue == title;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1E293B))),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade400, width: 2),
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
        ),
        child: isSelected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
      ),
      onTap: () => setState(() => _selectedValue = title),
    );
  }
}