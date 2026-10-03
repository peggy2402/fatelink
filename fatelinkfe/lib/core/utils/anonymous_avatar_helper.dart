import 'package:flutter/material.dart';
import '../../data/models/match_user.dart';

/// Helper quản lý Avatar ẩn danh và diện mạo chuẩn của FateLink
class AnonymousAvatarHelper {
  AnonymousAvatarHelper._();

  /// Tổng số avatar ẩn danh hiện có trong assets/avatars/
  static const int totalAvatars = 6;

  /// Lấy đường dẫn avatar ẩn danh cố định (deterministic) dựa trên userId
  static String getAnonymousAvatarAsset(String userId) {
    if (userId.isEmpty) {
      return 'assets/avatars/avatar_1.png';
    }
    final index = (userId.hashCode.abs() % totalAvatars) + 1;
    return 'assets/avatars/avatar_$index.png';
  }

  /// Tên linh vật của từng avatar ẩn danh tương ứng
  static String getAnonymousPersonaName(String userId) {
    const personaNames = [
      'Mèo Vũ Trụ',
      'Cáo Tinh Tú',
      'Thỏ Ánh Trăng',
      'Gấu Thiên Hà',
      'Hươu Tinh Thể',
      'Sinh Mệnh Âm Nhạc',
    ];
    if (userId.isEmpty) return personaNames[0];
    final index = userId.hashCode.abs() % personaNames.length;
    return personaNames[index];
  }

  /// Widget hiển thị Avatar thông minh: tự động chuyển giữa Avatar Ẩn Danh và Diện mạo thật
  static Widget buildAvatar({
    required MatchUser user,
    double size = 56,
    bool showLockBadge = true,
    BoxBorder? border,
    Gradient? customGradient,
  }) {
    final bool canView = user.canViewIdentity;
    final String anonymousAsset = getAnonymousAvatarAsset(user.id);
    final String? realAvatarUrl = user.avatar;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Khung viền gradient phát sáng
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: customGradient ??
                const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            border: border,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.22),
                blurRadius: size * 0.15,
                offset: Offset(0, size * 0.05),
              ),
            ],
          ),
          child: ClipOval(
            child: canView
                ? (realAvatarUrl != null && realAvatarUrl.isNotEmpty
                    ? Image.network(
                        realAvatarUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackDefaultAvatar(size),
                      )
                    : _buildFallbackDefaultAvatar(size))
                : Image.asset(
                    anonymousAsset,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackDefaultAvatar(size),
                  ),
          ),
        ),

        // Huy hiệu ổ khóa nhỏ tinh tế nếu đang ở chế độ ẩn danh
        if (!canView && showLockBadge && size >= 40)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: (size * 0.22).clamp(10.0, 16.0),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildFallbackDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFEDE9FE),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: const Color(0xFF8B5CF6),
        size: size * 0.5,
      ),
    );
  }
}
