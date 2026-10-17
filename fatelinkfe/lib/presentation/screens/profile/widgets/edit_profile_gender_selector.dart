import 'package:flutter/material.dart';

class EditProfileGenderSelector extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  const EditProfileGenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  Widget _buildGenderOption(
    String key,
    String label,
    IconData icon,
    Color activeColor,
  ) {
    final isSelected = selectedGender == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => onGenderChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildGenderOption(
              'female',
              'Nữ',
              Icons.female_rounded,
              const Color(0xFFEC4899),
            ),
            const SizedBox(width: 10),
            _buildGenderOption(
              'male',
              'Nam',
              Icons.male_rounded,
              const Color(0xFF6366F1),
            ),
            const SizedBox(width: 10),
            _buildGenderOption(
              'other',
              'Khác',
              Icons.all_inclusive_rounded,
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ],
    );
  }
}
