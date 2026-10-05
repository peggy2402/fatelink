import 'package:flutter/material.dart';
import '../../data/models/match_user.dart';

/// Helper quản lý Avatar ẩn danh và diện mạo chuẩn của FateLink
/// Hỗ trợ ma trận 120+ biến thể Avatar vũ trụ độc bản và 400+ tổ hợp danh xưng linh thú
class AnonymousAvatarHelper {
  AnonymousAvatarHelper._();

  /// Tổng số avatar base hiện có trong assets/avatars/
  static const int totalAvatars = 12;

  /// Danh sách 20 loài linh thú vũ trụ thần thoại (Archetype Species)
  static const List<String> personaSpecies = [
    'Mèo',
    'Cáo',
    'Thỏ',
    'Hươu',
    'Sói',
    'Cá Voi',
    'Gấu',
    'Phượng Hoàng',
    'Cú Đêm',
    'Kỳ Lân',
    'Rồng Sao',
    'Thiên Nga',
    'Hải Âu',
    'Bướm Đêm',
    'Báo Tuyết',
    'Chim Ưng',
    'Rái Cá',
    'Gấu Trúc',
    'Hạc Tiên',
    'Sư Tử Sao',
  ];

  /// Danh sách 20 cõi thuộc tính & năng lượng vũ trụ (Cosmic Realms & Elements)
  static const List<String> personaRealms = [
    'Vũ Trụ',
    'Tinh Tú',
    'Ánh Trăng',
    'Hào Quang',
    'Bụi Sao',
    'Dạ Nguyệt',
    'Thái Dương',
    'Pha Lê',
    'Tinh Cầu',
    'Hư Không',
    'Rực Rỡ',
    'Âm Nhạc',
    'Bắc Cực',
    'Tinh Vân',
    'Trầm Lặng',
    'Giấc Mơ',
    'Tương Lai',
    'Ngân Hà',
    'Bất Diệt',
    'Thời Không',
  ];

  /// 10 dải hào quang tần số rung động vũ trụ (Cosmic Solfeggio Aura Gradients)
  /// Tạo nên 12 base × 10 hào quang = 120+ biến thể Avatar thị giác độc bản
  static const List<LinearGradient> cosmicAuras = [
    // 1. Cosmic Pulse (432Hz - Tần số rung động định mệnh)
    LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 2. Electric Cyan (528Hz - Tương thích tần số cao)
    LinearGradient(
      colors: [Color(0xFF00E5FF), Color(0xFF3B82F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 3. Emerald Healer (528Hz - Tái sinh & Chữa lành tâm hồn)
    LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF059669)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 4. Golden Solfeggio (852Hz - Trực giác tâm linh & Hoàng kim)
    LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 5. Crown Awakening (963Hz - Luân xa vương miện & Tỉnh thức)
    LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 6. Rose Heart (639Hz - Kết nối nhịp đập & Tình yêu vô điều kiện)
    LinearGradient(
      colors: [Color(0xFFF43F5E), Color(0xFFBE185D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 7. Aurora Borealis (Cực quang phương Bắc huyền diệu)
    LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF10B981), Color(0xFF6366F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 8. Supernova Burst (Bùng nổ siêu tân tinh)
    LinearGradient(
      colors: [Color(0xFFFF5E3A), Color(0xFFFF2A68)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 9. Starlight Nebula (Tinh vân ánh sao huyền ảo)
    LinearGradient(
      colors: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF00E5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 10. Cosmic Obsidian (Hư không bí ẩn & Tĩnh lặng)
    LinearGradient(
      colors: [Color(0xFF64748B), Color(0xFF1E293B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  /// Lấy đường dẫn avatar ẩn danh cố định (deterministic) dựa trên userId
  static String getAnonymousAvatarAsset(String userId) {
    if (userId.isEmpty) {
      return 'assets/avatars/avatar_1.png';
    }
    final index = (userId.hashCode.abs() % totalAvatars) + 1;
    return 'assets/avatars/avatar_$index.png';
  }

  /// Lấy dải hào quang Cosmic Aura Gradient độc bản cho userId
  static LinearGradient getCosmicAuraGradient(String userId) {
    if (userId.isEmpty) return cosmicAuras[0];
    final auraIndex = (userId.hashCode.abs() ~/ totalAvatars) % cosmicAuras.length;
    return cosmicAuras[auraIndex];
  }

  /// Sinh danh xưng linh thú vũ trụ độc bản (Generative Cosmic Persona Name)
  /// Kết hợp 20 loài linh thú × 20 cõi vũ trụ = 400 tổ hợp tên tự nhiên, thi vị
  static String getAnonymousPersonaName(String userId) {
    if (userId.isEmpty) return '${personaSpecies[0]} ${personaRealms[0]}';

    final hash = userId.hashCode.abs();
    final speciesIndex = hash % personaSpecies.length;
    final realmIndex = (hash ~/ personaSpecies.length) % personaRealms.length;

    return '${personaSpecies[speciesIndex]} ${personaRealms[realmIndex]}';
  }

  /// Lấy danh xưng kèm mã tần số định mệnh vũ trụ (ví dụ: Mèo Vũ Trụ #432)
  static String getAnonymousPersonaBadge(String userId) {
    if (userId.isEmpty) return 'Mèo Vũ Trụ #432';
    const frequencies = ['432', '528', '639', '741', '852', '963', '396', '417'];
    final freqIndex = userId.hashCode.abs() % frequencies.length;
    return '${getAnonymousPersonaName(userId)} #${frequencies[freqIndex]}';
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
    final LinearGradient auraGradient = customGradient is LinearGradient
        ? customGradient
        : (customGradient ?? getCosmicAuraGradient(user.id)) as LinearGradient;

    final Color primaryGlowColor = auraGradient.colors.first;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Khung viền gradient hào quang năng lượng vũ trụ
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: auraGradient,
            border: border,
            boxShadow: [
              BoxShadow(
                color: primaryGlowColor.withValues(alpha: 0.28),
                blurRadius: size * 0.18,
                offset: Offset(0, size * 0.04),
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

        // Huy hiệu ổ khóa nhỏ tinh tế ở góc dưới bên phải nếu đang ở chế độ ẩn danh
        if (!canView && showLockBadge && size >= 36)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: EdgeInsets.all(size * 0.055),
              decoration: BoxDecoration(
                gradient: auraGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
