import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../presentation/widgets/back.dart';

/// AppBar phòng chat với Faye AI (ChatRoomAppBar):
/// - Nút quay lại danh sách
/// - Avatar Faye AI kèm quầng sáng và huy hiệu BOT
/// - Trạng thái hoạt động thời gian thực
class ChatRoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback? onOptionsTap;

  const ChatRoomAppBar({
    super.key,
    required this.onBack,
    this.onOptionsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62.0);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.85),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: CustomBackButton(onPressed: onBack),
          ),
          leadingWidth: 54,
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
                  radius: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Faye AI',
                            style: TextStyle(
                              color: Colors.grey.shade900,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFF00B8D4)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Đang hoạt động...',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
              onPressed: onOptionsTap ?? () {},
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
