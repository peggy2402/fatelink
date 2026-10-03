import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../core/services/image_picker_service.dart';
import '../../core/utils/anonymous_avatar_helper.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../../core/utils/toast_utils.dart';
import '../../data/models/match_user.dart';
import '../screens/match/match_chat_screen.dart';

/// Modal Popup Vũ Trụ khi nhận được Tín Hiệu Sóng 432Hz:
/// - Làm mờ toàn bộ màn hình phía sau (BackdropFilter Blur)
/// - Hiển thị thẻ người vừa gửi sóng với hiệu ứng hào quang phát sáng
/// - Bộ mô phỏng sóng âm thanh 432Hz chuyển động sống động
/// - 2 Nút hành động chuẩn nghiệp vụ:
///   + "Phát sóng đáp lại ⚡" (gọi API sóng thật)
///   + "Thả tim kết nối 💕" (mở khóa trò chuyện chỉ khi cả hai cùng thả tim)
class CosmicPulseReceivedModal extends StatefulWidget {
  final MatchUser sender;
  final VoidCallback? onResonated;

  const CosmicPulseReceivedModal({
    super.key,
    required this.sender,
    this.onResonated,
  });

  /// Phương thức static tiện lợi để kích hoạt popup từ bất kỳ đâu trong ứng dụng
  static Future<void> show(
    BuildContext context, {
    required MatchUser sender,
    VoidCallback? onResonated,
  }) {
    HapticFeedback.heavyImpact();

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CosmicPulseModal',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => CosmicPulseReceivedModal(
        sender: sender,
        onResonated: onResonated,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  State<CosmicPulseReceivedModal> createState() => _CosmicPulseReceivedModalState();
}

class _CosmicPulseReceivedModalState extends State<CosmicPulseReceivedModal>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _soundWaveController;
  bool _hasResonatedBack = false;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();

    // Animation vòng sóng xung kích tỏa ra từ avatar
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Animation các cột sóng âm thanh 432Hz dao động
    _soundWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _soundWaveController.dispose();
    super.dispose();
  }

  /// Gửi sóng 432Hz đáp lại người gửi
  Future<void> _handleResonateBack() async {
    if (_hasResonatedBack) return;
    HapticFeedback.heavyImpact();
    setState(() => _hasResonatedBack = true);

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && mounted) {
        final url =
            '${AppConstants.baseUrl}/${AppConstants.userRecordWave(widget.sender.id)}';
        await ApiService.post(url, context, token: token);
      }
    } catch (e) {
      debugPrint('Lỗi gửi sóng đáp lại: $e');
    }

    if (mounted) {
      ToastUtil.showSuccess(
        context,
        'Đã phát sóng 432Hz đáp lại! Hai bạn đã tạo nên sự cộng hưởng định mệnh ✨',
      );
    }

    widget.onResonated?.call();

    // Đóng sau 1.2 giây để người dùng cảm nhận hiệu ứng thành công
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// Xử lý Thả tim hoặc Mở chat (Nếu đã mutual match)
  Future<void> _handleHeartOrChat() async {
    // Nếu cả hai đã cùng thả tim từ trước -> Mở thẳng phòng trò chuyện
    if (widget.sender.isMutualFollow) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MatchChatScreen(
            partnerName: widget.sender.displayName,
            partnerId: widget.sender.id,
          ),
        ),
      );
      return;
    }

    // Nếu chưa cùng thả tim -> Thực hiện hành động thả tim
    if (_isLiking) return;
    HapticFeedback.heavyImpact();
    setState(() => _isLiking = true);

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && mounted) {
        final url =
            '${AppConstants.baseUrl}/${AppConstants.userToggleLike(widget.sender.id)}';
        final res = await ApiService.post(url, context, token: token);

        if (res != null && mounted) {
          final isMutual = res['isMutual'] == true;
          Navigator.of(context).pop();

          if (isMutual) {
            ToastUtil.showSuccess(
              context,
              '✨ Siêu tân tinh bùng nổ! Cả hai đã cùng thả tim! Trò chuyện đã được mở khóa.',
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MatchChatScreen(
                  partnerName: widget.sender.name.isNotEmpty
                      ? widget.sender.name
                      : widget.sender.displayName,
                  partnerId: widget.sender.id,
                ),
              ),
            );
          } else {
            ToastUtil.showSuccess(
              context,
              'Đã gửi rung động tim! Khi đối phương thả tim lại, diện mạo và trò chuyện sẽ mở khóa 💕',
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Lỗi thả tim kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sender = widget.sender;
    final canView = sender.canViewIdentity;
    final distanceText = sender.distanceKm != null && sender.distanceKm! > 0
        ? '${sender.distanceKm!.toStringAsFixed(1)} km'
        : 'Gần bạn';

    final bioText = (sender.bio != null && sender.bio!.trim().isNotEmpty)
        ? sender.bio!.trim()
        : 'Đang phát sóng cảm xúc 432Hz tìm kiếm tâm hồn đồng điệu...';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.22),
                    blurRadius: 36,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Nút đóng góc trên phải
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Huy hiệu sóng âm thanh 432Hz đang phát
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 5.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF00E5FF)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sensors_rounded, color: Colors.white, size: 15),
                              SizedBox(width: 5),
                              Text(
                                'TẦN SỐ 432Hz ĐANG RUNG ĐỘNG',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Avatar trung tâm với vòng hào quang phát sóng lan tỏa (Được thiết kế hoàn hảo không đè viền)
                        _buildCosmicAvatar(sender, canView),

                        const SizedBox(height: 14),

                        // 3. Tên bí danh + Giới tính/Tuổi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                canView ? sender.name : sender.anonymousName,
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: sender.resolvedGender == 'female'
                                    ? const Color(0xFFFDF2F8)
                                    : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sender.resolvedGender == 'female'
                                      ? const Color(0xFFF472B6)
                                      : const Color(0xFF818CF8),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${sender.genderLabel} • ${sender.resolvedAge}',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: sender.resolvedGender == 'female'
                                      ? const Color(0xFFDB2777)
                                      : const Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Thông tin khoảng cách & Cảm xúc
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cách bạn $distanceText',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${sender.emotion}',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 4. Card Tương Hợp Tâm Hồn
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${sender.compatibilityScore}%',
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Đồng điệu tần số cảm xúc',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              // Bộ visualizer sóng âm dao động
                              _buildSoundwaveVisualizer(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Lời thì thầm / Bio
                        Text(
                          '"$bioText"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 20),

                        // 5. Hai nút hành động chuẩn nghiệp vụ: "Phát sóng đáp lại" & "Thả tim kết nối"
                        Row(
                          children: [
                            // Nút Phát sóng đáp lại
                            Expanded(
                              flex: 5,
                              child: GestureDetector(
                                onTap: _handleResonateBack,
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: _hasResonatedBack
                                        ? const LinearGradient(
                                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                                          )
                                        : const LinearGradient(
                                            colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                                          ),
                                    borderRadius: BorderRadius.circular(23),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_hasResonatedBack
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEC4899))
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _hasResonatedBack
                                            ? Icons.check_circle_rounded
                                            : Icons.bolt_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _hasResonatedBack
                                            ? 'Đã cộng hưởng ✨'
                                            : 'Phát sóng đáp lại',
                                        style: const TextStyle(
                                          fontFamily: 'BeVietnamPro',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Nút Thả tim kết nối (hoặc Trò chuyện nếu đã là bạn bè mutual match)
                            Expanded(
                              flex: 5,
                              child: GestureDetector(
                                onTap: _handleHeartOrChat,
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: sender.isMutualFollow
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFFDF2F8),
                                    borderRadius: BorderRadius.circular(23),
                                    border: Border.all(
                                      color: sender.isMutualFollow
                                          ? const Color(0xFFC7D2FE)
                                          : const Color(0xFFFBCFE8),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        sender.isMutualFollow
                                            ? Icons.chat_bubble_outline_rounded
                                            : Icons.favorite_rounded,
                                        color: sender.isMutualFollow
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFFEC4899),
                                        size: 17,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        sender.isMutualFollow
                                            ? 'Trò chuyện'
                                            : 'Thả tim kết nối',
                                        style: TextStyle(
                                          fontFamily: 'BeVietnamPro',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: sender.isMutualFollow
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFFEC4899),
                                        ),
                                      ),
                                    ],
                                  ),
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
        ),
      ),
    );
  }

  /// Khung hiển thị Avatar Cosmic: Đồng tâm, không đè viền, tinh xảo tuyệt đối
  Widget _buildCosmicAvatar(MatchUser sender, bool canView) {
    const double avatarSize = 78.0;

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Vòng sóng siêu âm 432Hz lan tỏa đồng tâm
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) {
              final progress = _rippleController.value;
              final scale = 1.0 + progress * 0.35;
              final opacity = (1.0 - progress) * 0.45;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: avatarSize + 6,
                  height: avatarSize + 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEC4899).withValues(alpha: opacity),
                      width: 1.8,
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Avatar tròn đơn nhất với 1 viền Gradient duy nhất
          Container(
            width: avatarSize,
            height: avatarSize,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: canView
                  ? (sender.avatar != null && sender.avatar!.isNotEmpty
                      ? Image(
                          image: ImagePickerService.getImageProvider(sender.avatar!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackAvatar(avatarSize),
                        )
                      : _buildFallbackAvatar(avatarSize))
                  : Image.asset(
                      AnonymousAvatarHelper.getAnonymousAvatarAsset(sender.id),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackAvatar(avatarSize),
                    ),
            ),
          ),

          // 3. Huy hiệu Mood (nếu có): Đặt gọn gàng góc trên phải
          if (sender.moodIcon != null && sender.moodIcon!.isNotEmpty)
            Positioned(
              top: 4,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  sender.moodIcon!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),

          // 4. Huy hiệu Ổ Khóa (nếu đang ở chế độ ẩn danh): Đặt gọn gàng góc dưới phải
          if (!canView)
            Positioned(
              bottom: 4,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFEDE9FE),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF8B5CF6),
        size: 32,
      ),
    );
  }

  /// Bộ mô phỏng các cột sóng âm thanh 432Hz đang dao động
  Widget _buildSoundwaveVisualizer() {
    return AnimatedBuilder(
      animation: _soundWaveController,
      builder: (context, child) {
        final val = _soundWaveController.value;
        final heights = [
          8.0 + 8.0 * (val),
          14.0 - 6.0 * (val),
          6.0 + 10.0 * (1.0 - val),
          12.0 + 4.0 * (val),
          7.0 + 7.0 * (1.0 - val),
        ];

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: heights.map((h) {
            return Container(
              width: 2.5,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
