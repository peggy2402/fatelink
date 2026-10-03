import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/models/vibe_photo_item.dart';

/// Modal Glassmorphism cho phép người dùng chọn thời hạn tự hủy của ảnh Vibe (Góc tâm hồn)
class VibeDurationPickerModal extends StatefulWidget {
  final int photoCount;
  final VibeDurationOption initialOption;

  const VibeDurationPickerModal({
    super.key,
    required this.photoCount,
    this.initialOption = VibeDurationOption.twentyFourHours,
  });

  /// Hiển thị modal và trả về tùy chọn được chọn
  static Future<VibeDurationOption?> show(
    BuildContext context, {
    int photoCount = 1,
    VibeDurationOption initialOption = VibeDurationOption.twentyFourHours,
  }) {
    return showModalBottomSheet<VibeDurationOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VibeDurationPickerModal(
        photoCount: photoCount,
        initialOption: initialOption,
      ),
    );
  }

  @override
  State<VibeDurationPickerModal> createState() => _VibeDurationPickerModalState();
}

class _VibeDurationPickerModalState extends State<VibeDurationPickerModal> {
  late VibeDurationOption _selectedOption;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.timer_outlined, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thời hạn ảnh Góc tâm hồn (${widget.photoCount} ảnh)',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ảnh sẽ tự động biến mất và giải phóng bộ nhớ khi hết hạn để bảo vệ quyền riêng tư & tiết kiệm dung lượng.',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Danh sách các tùy chọn thời gian
              ...VibeDurationOption.values.map((option) {
                final isSelected = _selectedOption == option;
                final isRecommended = option == VibeDurationOption.twentyFourHours;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOption = option;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1).withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.015),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          // Emoji Icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                option.icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text Label & Description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      option.label,
                                      style: TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 14.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (isRecommended) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Khuyên dùng',
                                          style: TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFEC4899),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option.description,
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 11.5,
                                    color: isSelected ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Radio check icon
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check, size: 14, color: Colors.white),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Nút xác nhận lưu
              SizedBox(
                width: double.infinity,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedOption),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Thiết lập & Tải ảnh (${_selectedOption.label})',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
