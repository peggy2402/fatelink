import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/toast_utils.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String type; // 'match', 'faye', 'system'
  final String? avatarAsset;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.avatarAsset,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}

class NotificationsModal extends StatefulWidget {
  final VoidCallback? onClearBadge;

  const NotificationsModal({super.key, this.onClearBadge});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onClearBadge,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsModal(onClearBadge: onClearBadge),
    );
  }

  @override
  State<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal> {
  String _selectedFilter = 'all'; // 'all', 'match', 'system'

  late final List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: '1',
        title: 'Tần số tương hợp mới! ✨',
        message: 'Soul#W13X8 vừa hòa âm cùng tần số "Bình yên" của bạn với độ tương thích lên đến 92%.',
        time: '5 phút trước',
        type: 'match',
        avatarAsset: 'assets/avatars/avatar_1.png',
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFEC4899),
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Ai đó vừa thả tim bạn! 💕',
        message: 'Một tâm hồn bí ẩn vừa thả tim hồ sơ của bạn. Cùng thả tim để mở khóa diện mạo nhé!',
        time: '1 giờ trước',
        type: 'match',
        avatarAsset: 'assets/avatars/avatar_3.png',
        icon: Icons.lock_open_rounded,
        iconColor: const Color(0xFF8B5CF6),
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Gợi ý kết nối từ Faye AI 🔮',
        message: 'Đêm nay là thời điểm lý tưởng cho những câu chuyện sâu lắng (#DeepTalk). Có 3 người đang phát sóng gần bạn!',
        time: 'Hôm nay 22:30',
        type: 'system',
        avatarAsset: 'assets/icon/app_logo.png',
        icon: Icons.auto_awesome,
        iconColor: const Color(0xFF6366F1),
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'Chào mừng bạn đến với Meyu! 🚀',
        message: 'Khám phá thế giới qua lăng kính cảm xúc và kết nối những tâm hồn đồng điệu nhất.',
        time: 'Hôm qua',
        type: 'system',
        icon: Icons.celebration_rounded,
        iconColor: const Color(0xFF10B981),
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    HapticFeedback.lightImpact();
    widget.onClearBadge?.call();
    ToastUtil.showSuccess(context, 'Đã đánh dấu đã đọc tất cả thông báo');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final filteredList = _notifications.where((n) {
      if (_selectedFilter == 'match') return n.type == 'match';
      if (_selectedFilter == 'system') return n.type == 'system';
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x300F172A),
            blurRadius: 32,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Thanh kéo handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // 2. Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFFEC4899),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Thông báo',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount mới',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: unreadCount > 0 ? _markAllAsRead : null,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                  child: const Text(
                    'Đã đọc hết',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả'),
                const SizedBox(width: 8),
                _buildFilterChip('match', 'Tương hợp 💗'),
                const SizedBox(width: 8),
                _buildFilterChip('system', 'Hệ thống ✦'),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 4. Danh sách thông báo
          Flexible(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          item.isRead = true;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFE0E7FF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: item.isRead ? 0.02 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar hoặc Icon
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: item.avatarAsset != null
                      ? ClipOval(
                          child: Image.asset(
                            item.avatarAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              item.icon,
                              color: item.iconColor,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(
                          item.icon,
                          color: item.iconColor,
                          size: 22,
                        ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: item.iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      item.icon,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEC4899),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      color: item.isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                size: 26,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Không có thông báo nào trong mục này',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
