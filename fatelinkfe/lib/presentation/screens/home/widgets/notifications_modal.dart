import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/api_service.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/secure_storage_helper.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../data/models/match_user.dart';
import '../../profile/user_detail_screen.dart';
import '../../../../core/utils/anonymous_avatar_helper.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type; // 'like', 'mutual_like', 'view', 'wave', 'system'
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Thông báo',
      message: json['message']?.toString() ?? '',
      createdAt: parsedDate,
      type: json['type']?.toString() ?? 'system',
      senderId: json['senderId']?.toString(),
      senderName: json['senderName']?.toString(),
      senderAvatar: json['senderAvatar']?.toString(),
      isRead: json['isRead'] == true,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      final hour = createdAt.hour.toString().padLeft(2, '0');
      final minute = createdAt.minute.toString().padLeft(2, '0');
      return 'Hôm qua $hour:$minute';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    }
  }

  IconData get icon {
    switch (type) {
      case 'like':
      case 'mutual_like':
        return Icons.favorite_rounded;
      case 'view':
        return Icons.visibility_rounded;
      case 'wave':
        return Icons.waves_rounded;
      case 'system':
      default:
        return Icons.auto_awesome;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'like':
        return const Color(0xFFEC4899);
      case 'mutual_like':
        return const Color(0xFFF43F5E);
      case 'view':
        return const Color(0xFF8B5CF6);
      case 'wave':
        return const Color(0xFF00E5FF);
      case 'system':
      default:
        return const Color(0xFF6366F1);
    }
  }

  String get filterCategory {
    if (type == 'system') return 'system';
    return 'match';
  }
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
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && mounted) {
        final url = '${AppConstants.baseUrl}/${AppConstants.notifications}';
        final res = await ApiService.get(url, context, token: token);
        List<dynamic>? rawList;
        if (res is List) {
          rawList = res;
        } else if (res is Map<String, dynamic> && res['data'] is List) {
          rawList = res['data'] as List;
        }

        if (rawList != null && mounted) {
          final list = rawList
              .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
              .toList();
          setState(() {
            _notifications = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải thông báo: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    HapticFeedback.lightImpact();
    widget.onClearBadge?.call();
    ToastUtil.showSuccess(context, 'Đã đánh dấu đã đọc tất cả thông báo');

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && mounted) {
        final url = '${AppConstants.baseUrl}/${AppConstants.markAllNotificationsRead}';
        await ApiService.patch(url, context, token: token, body: {});
      }
    } catch (e) {
      debugPrint('Lỗi đánh dấu tất cả đã đọc: $e');
    }
  }

  Future<void> _markSingleAsRead(NotificationItem item) async {
    if (!item.isRead) {
      setState(() {
        item.isRead = true;
      });
      HapticFeedback.lightImpact();
      try {
        final token = await SecureStorageHelper.read('accessToken');
        if (token != null && mounted) {
          final url =
              '${AppConstants.baseUrl}/${AppConstants.markNotificationRead(item.id)}';
          await ApiService.patch(url, context, token: token, body: {});
        }
      } catch (e) {
        debugPrint('Lỗi đánh dấu thông báo đã đọc: $e');
      }
    }

    // Nếu thông báo liên quan đến User khác -> Mở trang hồ sơ tương tác chuẩn chế độ ẩn danh
    if (item.senderId != null && item.senderId!.isNotEmpty && mounted) {
      final bool isMutual =
          item.type == 'mutual_like' || item.type == 'mutual_match';
      final matchUser = MatchUser(
        id: item.senderId!,
        name: item.senderName ?? 'Tâm hồn bí ẩn',
        emotion: 'Bình yên',
        compatibilityScore: 88,
        avatar: item.senderAvatar,
        isFaceLocked: !isMutual,
        isMutualFollow: isMutual,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UserDetailScreen(
            user: matchUser,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final filteredList = _notifications.where((n) {
      if (_selectedFilter == 'match') return n.filterCategory == 'match';
      if (_selectedFilter == 'system') return n.filterCategory == 'system';
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
                _buildFilterChip('match', 'Tương tác 💗'),
                const SizedBox(width: 8),
                _buildFilterChip('system', 'Hệ thống ✦'),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 4. Danh sách thông báo
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    ),
                  )
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: const Color(0xFF6366F1),
                        onRefresh: _fetchNotifications,
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return _buildNotificationCard(item);
                          },
                        ),
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
    final bool isUserAction =
        item.senderId != null && item.senderId!.trim().isNotEmpty;
    final bool isMutual =
        item.type == 'mutual_like' || item.type == 'mutual_match';

    MatchUser? tempUser;
    String displayTitle = item.title;
    String displayMessage = item.message;

    if (isUserAction) {
      tempUser = MatchUser(
        id: item.senderId!,
        name: item.senderName ?? 'Tâm hồn bí ẩn',
        emotion: 'Bình yên',
        compatibilityScore: 88,
        avatar: item.senderAvatar,
        isFaceLocked: !isMutual,
        isMutualFollow: isMutual,
      );

      // Nếu chưa cùng thả tim (chưa mutual match) -> Ẩn danh tuyệt đối
      if (!isMutual) {
        final alias = tempUser.displayName;
        if (item.type == 'like') {
          displayTitle = 'Ai đó vừa thả tim bạn! 💕';
          displayMessage =
              'Một tâm hồn đồng điệu ($alias) vừa thả tim hồ sơ của bạn. Cùng thả tim lại để mở khóa diện mạo nhé!';
        } else if (item.type == 'view' || item.type == 'view_profile') {
          displayTitle = 'Ai đó vừa ghé thăm tần số của bạn! ✨';
          displayMessage =
              'Một tâm hồn đồng điệu ($alias) vừa dừng chân ghé thăm hồ sơ và tần số cảm xúc của bạn.';
        } else if (item.type == 'wave') {
          displayTitle = 'Tín hiệu sóng rung cảm mới! 🌊';
          displayMessage =
              'Một tâm hồn đồng điệu ($alias) vừa phát sóng rung cảm hướng về bạn!';
        } else {
          // Che tên thật trong message nếu có
          if (item.senderName != null && item.senderName!.isNotEmpty) {
            displayMessage = displayMessage.replaceAll(item.senderName!, alias);
          }
        }
      }
    }

    return GestureDetector(
      onTap: () => _markSingleAsRead(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFE0E7FF),
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
            // Avatar chuẩn mực: Tự động ẩn danh linh vật vũ trụ hoặc hiện ảnh thật khi mutual
            if (isUserAction && tempUser != null)
              AnonymousAvatarHelper.buildAvatar(
                user: tempUser,
                size: 46,
                showLockBadge: !isMutual,
              )
            else
              // Icon thông báo hệ thống
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
                    child: Icon(
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

            // Nội dung thông báo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 14,
                            fontWeight:
                                item.isRead ? FontWeight.w700 : FontWeight.w800,
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
                    displayMessage,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      color: item.isRead
                          ? const Color(0xFF64748B)
                          : const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.timeAgo,
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
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
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
