import 'package:flutter/material.dart';

class EditProfileInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final bool isReadOnly;
  final String? helperText;
  final Widget? trailing;

  const EditProfileInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.isReadOnly = false,
    this.helperText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            if (showCounter && maxLength != null)
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final len = controller.text.characters.length;
                  final isNearLimit = len >= (maxLength! * 0.9);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isNearLimit
                          ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$len/$maxLength',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isNearLimit
                            ? const Color(0xFFEC4899)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  );
                },
              ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          buildCounter: showCounter
              ? (_, {required currentLength, required isFocused, maxLength}) =>
                    null
              : null,
          readOnly: isReadOnly,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 15,
            color: isReadOnly
                ? const Color(0xFF64748B)
                : const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1
                ? Icon(
                    icon,
                    color: isReadOnly
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF94A3B8),
                    size: 20,
                  )
                : null,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontFamily: 'BeVietnamPro',
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
            ),
            filled: true,
            fillColor: isReadOnly ? const Color(0xFFF1F5F9) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isReadOnly
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF6366F1),
                width: isReadOnly ? 1 : 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11.5,
              color: isReadOnly
                  ? const Color(0xFFD97706)
                  : const Color(0xFF64748B),
              fontWeight: isReadOnly ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
