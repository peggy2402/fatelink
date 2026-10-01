import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String? avatarUrl;
  final String? userName;
  final String? userHandle;
  final bool isPro;
  final VoidCallback? onSearchTap;
  final VoidCallback? onQrTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  const HomeHeader({
    super.key,
    this.avatarUrl,
    this.userName,
    this.userHandle,
    this.isPro = false,
    this.onSearchTap,
    this.onQrTap,
    this.onNotificationTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 370;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 14.0 : 20.0, vertical: 8.0),
      child: Row(
        children: [
          // --- Avatar với viền phát sáng (Glowing Ring) ---
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF6366F1), Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFF3E8FF),
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!) as ImageProvider
                      : const AssetImage('assets/images/default_avatar.png'),
                ),
              ),
              // Online dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Emerald online
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // --- Tên người dùng & Handle (Đã bỏ badge PRO để tên hiển thị trọn vẹn) ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName ?? 'Bạn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userHandle ?? '@soulconnector',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6366F1), // Indigo
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // --- Nút hành động dạng Glassmorphism ---
          _buildActionButtons(isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _buildActionButtons({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconButton(Icons.search_rounded, onSearchTap, isCompact: isCompact),
          _buildIconButton(Icons.qr_code_scanner_rounded, onQrTap, isCompact: isCompact),
          _buildNotificationButton(isCompact: isCompact),
          _buildIconButton(Icons.settings_outlined, onSettingsTap, isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onTap, {bool isCompact = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 5.0 : 7.0),
          child: Icon(icon, color: const Color(0xFF334155), size: isCompact ? 18 : 20),
        ),
      ),
    );
  }

  Widget _buildNotificationButton({bool isCompact = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onNotificationTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 5.0 : 7.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 20),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
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
