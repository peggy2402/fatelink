import 'dart:ui';
import 'package:flutter/material.dart';

class MatchChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isMultiSelectMode;
  final int selectedCount;
  final VoidCallback onCloseMultiSelect;
  final VoidCallback onDeleteSelected;
  final String partnerDisplayName;
  final Widget partnerAvatarWidget;
  final String partnerHertz;
  final bool isPartnerOnline;
  final VoidCallback onBack;
  final VoidCallback onPartnerProfileTap;
  final VoidCallback onStartVoiceCall;
  final VoidCallback onOptionsTap;

  const MatchChatAppBar({
    super.key,
    required this.isMultiSelectMode,
    required this.selectedCount,
    required this.onCloseMultiSelect,
    required this.onDeleteSelected,
    required this.partnerDisplayName,
    required this.partnerAvatarWidget,
    required this.partnerHertz,
    required this.isPartnerOnline,
    required this.onBack,
    required this.onPartnerProfileTap,
    required this.onStartVoiceCall,
    required this.onOptionsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    if (isMultiSelectMode) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
          onPressed: onCloseMultiSelect,
        ),
        title: Text(
          'Đã chọn $selectedCount tin nhắn',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Xóa hoặc thu hồi',
              onPressed: onDeleteSelected,
            ),
        ],
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFFF1E5ED),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  // Nút Back
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF0F172A),
                      size: 30,
                    ),
                    onPressed: onBack,
                  ),

                  // Nhấn vào Avatar hoặc Tên để xem Profile đối phương
                  Expanded(
                    child: GestureDetector(
                      onTap: onPartnerProfileTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              partnerAvatarWidget,
                              // Trạng thái Online
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isPartnerOnline
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),

                          // Tên đối phương & Tần số
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  partnerDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    color: Color(0xFF0F172A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.sensors_rounded,
                                      color: isPartnerOnline
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF6366F1),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        isPartnerOnline
                                            ? '$partnerHertz • Đang phát sóng'
                                            : '$partnerHertz • Ngoại tuyến',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'BeVietnamPro',
                                          color: isPartnerOnline
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF64748B),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Nút Gọi thoại trực tiếp
                  IconButton(
                    tooltip: 'Cuộc gọi thoại',
                    icon: const Icon(
                      Icons.phone_rounded,
                      color: Color(0xFF7C3AED),
                      size: 22,
                    ),
                    onPressed: onStartVoiceCall,
                  ),

                  // Nút Tuỳ chọn 3 chấm
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                    onPressed: onOptionsTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
