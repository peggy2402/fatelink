import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fatelinkfe/data/models/match_user.dart';
import 'package:fatelinkfe/presentation/screens/match/match_chat_screen.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/utils/anonymous_avatar_helper.dart';
import '../../widgets/cosmic_pulse_received_modal.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../data/models/vibe_photo_item.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../services/api_service.dart';
import '../../widgets/cosmic_report_modal.dart';

class UserDetailScreen extends StatefulWidget {
  final MatchUser user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late bool _isFollowing;
  late bool _isMutualFollow;
  late int _likesCount;
  bool _isWaveSent = false;

  // Danh sách ảnh Vibe khoảnh khắc mặc định nếu user chưa có
  static const List<String> defaultVibePhotos = [
    'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1518495973542-4542c06a5843?auto=format&fit=crop&w=400&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.user.isLiked || widget.user.isMutualFollow;
    _isMutualFollow = widget.user.isMutualFollow;
    _likesCount = widget.user.likesCount ?? 0;
    _recordProfileView();
  }

  Future<void> _recordProfileView() async {
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null &&
          widget.user.id.isNotEmpty &&
          !widget.user.id.startsWith('echo-')) {
        final url =
            '${AppConstants.baseUrl}/${AppConstants.userRecordView(widget.user.id)}';
        await ApiService.post(url, context, token: token);
      }
    } catch (_) {}
  }

  // Điều kiện hiển thị diện mạo: Cả 2 phải follow nhau VÀ đối phương không bật Khóa diện mạo
  bool get canViewIdentity => _isMutualFollow && !widget.user.isFaceLocked;

  Future<void> _toggleFollow() async {
    HapticFeedback.lightImpact();
    final nextState = !_isFollowing;
    setState(() {
      _isFollowing = nextState;
      if (nextState) {
        _likesCount += 1;
      } else {
        _likesCount = (_likesCount > 0) ? _likesCount - 1 : 0;
      }
    });

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null &&
          widget.user.id.isNotEmpty &&
          !widget.user.id.startsWith('echo-')) {
        final url =
            '${AppConstants.baseUrl}/${AppConstants.userToggleLike(widget.user.id)}';
        final res = await ApiService.post(url, context, token: token);
        if (res != null && mounted) {
          final isMutual = res['isMutual'] == true;
          final isLiked = res['isLiked'] == true;
          setState(() {
            _isFollowing = isLiked;
            _isMutualFollow = isMutual;
            if (res['likesReceived'] is num) {
              _likesCount = (res['likesReceived'] as num).toInt();
            }
          });
          if (isMutual) {
            ToastUtil.showSuccess(
              context,
              '✨ Định mệnh giao thoa! Cả hai đã cùng thả tim! Diện mạo đã được mở khóa.',
            );
            return;
          }
        }
      }
    } catch (_) {}

    if (nextState) {
      ToastUtil.showSuccess(context, 'Đã thả tim kết nối cùng đối phương 💕');
    } else {
      ToastUtil.showInfo(context, 'Đã bỏ thả tim đối phương');
    }
  }

  Future<void> _handleSendWave(String displayName) async {
    HapticFeedback.mediumImpact();
    setState(() => _isWaveSent = true);
    ToastUtil.showSuccess(
      context,
      'Đã phát sóng 432Hz tới $displayName! Tín hiệu đang lan tỏa ✨',
    );

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null &&
          widget.user.id.isNotEmpty &&
          !widget.user.id.startsWith('echo-')) {
        final url =
            '${AppConstants.baseUrl}/${AppConstants.userRecordWave(widget.user.id)}';
        await ApiService.post(url, context, token: token);
      }
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        CosmicPulseReceivedModal.show(context, sender: widget.user);
      }
    });
  }

  Future<void> _handleBlockUser() async {
    final displayName = canViewIdentity ? widget.user.name : widget.user.anonymousName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text(
              'Chặn người dùng?',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn chặn $displayName? Hai bạn sẽ không thể tìm thấy, gửi sóng hoặc xem hồ sơ của nhau nữa.',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Chặn vĩnh viễn',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && mounted) {
        final url =
            '${AppConstants.baseUrl}/${AppConstants.userBlock(widget.user.id)}';
        await ApiService.post(url, context, token: token, showLoading: true);
      }
      if (mounted) {
        ToastUtil.showSuccess(context, 'Đã chặn $displayName thành công');
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ToastUtil.showError(context, 'Lỗi thao tác chặn. Vui lòng thử lại!');
      }
    }
  }

  void _showUserOptionsModal() {
    final displayName = canViewIdentity ? widget.user.name : widget.user.anonymousName;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.flag_outlined, color: Color(0xFFF59E0B)),
              title: const Text(
                'Báo cáo hồ sơ này',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: const Text(
                'Gửi phản ánh nếu hồ sơ này vi phạm tiêu chuẩn',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                CosmicReportModal.show(
                  context,
                  targetUserId: widget.user.id,
                  targetUserName: displayName,
                  onReported: (blocked) {
                    if (blocked && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
              title: const Text(
                'Chặn người dùng này',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
              subtitle: const Text(
                'Cả hai sẽ không thể tương tác hoặc nhìn thấy nhau',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleBlockUser();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6366F1);
    const Color backgroundColor = Color(0xFFF8FAFC);

    final avatarUrl = widget.user.avatar ??
        'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(widget.user.name)}&backgroundColor=e0e7ff';
    final distance = widget.user.distanceKm != null
        ? '${widget.user.distanceKm} km'
        : 'Gần bạn';
    final tags = (widget.user.tags != null && widget.user.tags!.isNotEmpty)
        ? widget.user.tags!
        : ['#NhạcIndie', '#ĐêmMuộn', '#DeepTalk'];

    final vibePhotos = (widget.user.vibePhotos != null && widget.user.vibePhotos!.isNotEmpty)
        ? widget.user.vibePhotos!
        : defaultVibePhotos;

    final displayName = canViewIdentity ? widget.user.name : widget.user.anonymousName;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background ambient gradient mượt mà (Không dùng BackdropFilter tràn viền gây vệt vuông)
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withValues(alpha: 0.15),
                    const Color(0xFFEC4899).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.12),
                    primaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: ResponsiveCenter(
              maxWidth: 600,
              child: Column(
                children: [
                  // Top Custom App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          canViewIdentity ? 'Hồ sơ người dùng' : 'Hồ sơ tâm hồn (Ẩn danh)',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Nút trạng thái khóa diện mạo nhỏ ở góc
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: canViewIdentity
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFEC4899).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              canViewIdentity ? Icons.lock_open_rounded : Icons.lock_rounded,
                              size: 13,
                              color: canViewIdentity ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              canViewIdentity ? 'Đã mở' : 'Đang khóa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: canViewIdentity ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A), size: 22),
                        onPressed: _showUserOptionsModal,
                        tooltip: 'Tùy chọn',
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 100 + MediaQuery.paddingOf(context).bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar: Nếu canViewIdentity = false -> Hiệu ứng Kính Mờ (Blur) + Ổ Khóa
                        Builder(
                          builder: (context) {
                            final auraGradient = AnonymousAvatarHelper.getCosmicAuraGradient(widget.user.id);
                            final avatarBorderGradient = canViewIdentity
                                ? const LinearGradient(
                                    colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : auraGradient;

                            return Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  // Avatar Container with Gradient Border
                                  Container(
                                    width: 130,
                                    height: 130,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: avatarBorderGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: avatarBorderGradient.colors.first.withValues(alpha: 0.25),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image(
                                        image: canViewIdentity
                                            ? NetworkImage(avatarUrl) as ImageProvider
                                            : AssetImage(AnonymousAvatarHelper.getAnonymousAvatarAsset(widget.user.id)),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                                          radius: 60,
                                          backgroundColor: Color(0xFFE0E7FF),
                                          child: Icon(Icons.person_rounded, color: Color(0xFF6366F1), size: 60),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Mood icon ở góc trên bên phải (top-right) theo quy chuẩn UI/UX
                                  if (widget.user.moodIcon != null)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          widget.user.moodIcon!,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),

                                  // Huy hiệu ổ khóa ẩn danh ở góc dưới bên phải (bottom-right)
                                  if (!canViewIdentity)
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: auraGradient,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.lock_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Name & Verified or Lock Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (canViewIdentity)
                              const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 20)
                            else
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_rounded, color: Color(0xFFEC4899), size: 14),
                              ),
                          ],
                        ),

                        // Chip thông tin Linh vật Vũ trụ thanh lịch & không bao giờ vỡ avatar
                        if (!canViewIdentity) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withValues(alpha: 0.12),
                                  const Color(0xFFEC4899).withValues(alpha: 0.12),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF8B5CF6)),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Linh vật: ${AnonymousAvatarHelper.getAnonymousPersonaName(widget.user.id)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4F46E5),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),

                        // Distance & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text(
                              'Đang phát tần số',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Tần số cảm xúc Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.graphic_eq_rounded, color: Color(0xFF6366F1), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Tần số: ${widget.user.moodIcon != null ? "${widget.user.moodIcon} " : ""}${widget.user.emotion}',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Tags List (Gu sống)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: tags.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // --- THẺ CHỈ SỐ TÂM HỒN (SỐ LƯỢT TIM, HÒA HỢP, TẦN SỐ) ---
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 1. Số lượt tim
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isFollowing ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: const Color(0xFFEC4899),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$_likesCount',
                                          style: const TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Lượt tim',
                                      style: TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),

                              // 2. Độ tương hợp
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Color(0xFF6366F1),
                                          size: 17,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.user.compatibilityScore}%',
                                          style: const TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Độ hòa hợp',
                                      style: TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),

                              // 3. Tần số kết nối
                              const Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.bolt_rounded,
                                          color: Color(0xFF10B981),
                                          size: 19,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          '432 Hz',
                                          style: TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Tần số sóng',
                                      style: TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Soul Compatibility Card (Điểm tương thích nổi bật)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${widget.user.compatibilityScore}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tương thích tâm hồn',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Thuật toán AI nhận thấy bạn và $displayName có sự bù trừ cảm xúc và tần số đồng điệu rất cao.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- GÓC TÂM HỒN (VIBES GALLERY) ---
                        _buildVibesSection(vibePhotos),

                        const SizedBox(height: 18),

                        // Chi tiết phân tích tương hợp
                        _buildDetailCard(
                          title: 'Trạng thái tần số',
                          value: '${widget.user.moodIcon != null ? "${widget.user.moodIcon} " : ""}${widget.user.emotion}',
                          icon: Icons.graphic_eq_rounded,
                          color: const Color(0xFF8B5CF6),
                        ),
                        _buildDetailCard(
                          title: 'Nhu cầu kết nối',
                          value: widget.user.bio ?? 'Chia sẻ chân thành, lắng nghe sâu',
                          icon: Icons.chat_bubble_outline_rounded,
                          color: primaryColor,
                        ),
                        _buildDetailCard(
                          title: 'Khoảng cách địa lý',
                          value: distance,
                          icon: Icons.near_me_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Floating Bar (Nút Thả tim + Nút Chat)
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.paddingOf(context).bottom > 0
              ? MediaQuery.paddingOf(context).bottom + 10
              : 20,
          child: ResponsiveCenter(
            maxWidth: 500,
            child: Row(
              children: [
                // Nút Thả tim / Follow
                GestureDetector(
                  onTap: _toggleFollow,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isFollowing ? const Color(0xFFEC4899) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isFollowing ? const Color(0xFFEC4899) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isFollowing
                              ? const Color(0xFFEC4899).withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFollowing ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFollowing ? Colors.white : const Color(0xFFEC4899),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nút Hành Động Chính: "Trò chuyện ngay" (nếu đã kết nối) HOẶC "Gửi sóng 432Hz" (nếu chưa kết nối)
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_isMutualFollow
                                  ? const Color(0xFF6366F1)
                                  : (_isWaveSent ? const Color(0xFF10B981) : const Color(0xFFEC4899)))
                              .withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isMutualFollow) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MatchChatScreen(
                                partnerName: displayName,
                                partnerId: widget.user.id,
                              ),
                            ),
                          );
                        } else {
                          _handleSendWave(displayName);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMutualFollow
                            ? const Color(0xFF6366F1)
                            : (_isWaveSent ? const Color(0xFF10B981) : const Color(0xFFEC4899)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isMutualFollow
                                ? Icons.chat_bubble_rounded
                                : (_isWaveSent ? Icons.check_circle_rounded : Icons.bolt_rounded),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _isMutualFollow
                                  ? 'Trò chuyện ngay'
                                  : (_isWaveSent ? 'Đã phát sóng 432Hz' : 'Gửi sóng 432Hz'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  // Widget hiển thị mục Góc tâm hồn (Vibes) với kiểm tra khóa diện mạo
  Widget _buildVibesSection(List<String> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1), size: 20),
                SizedBox(width: 6),
                Text(
                  'Góc tâm hồn (Vibes)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            if (!canViewIdentity)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: Color(0xFFEC4899)),
                    SizedBox(width: 4),
                    Text(
                      'Khóa ảnh',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFEC4899)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          canViewIdentity
              ? 'Khoảnh khắc cuộc sống và cảm xúc của đối phương:'
              : (widget.user.isFaceLocked
                  ? '🔒 Người này đang bật tính năng Khóa diện mạo cá nhân.'
                  : '🔒 Thả tim kết nối cả hai bên để cùng mở khóa Góc tâm hồn & Diện mạo.'),
          style: TextStyle(
            fontSize: 12,
            color: canViewIdentity ? const Color(0xFF64748B) : const Color(0xFFEC4899),
            fontWeight: canViewIdentity ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Hàng ảnh Vibe
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final raw = photos[index];
              final item = VibePhotoItem.fromRaw(raw);
              return Container(
                width: 105,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(
                        image: ImagePickerService.getImageProvider(item.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.image_not_supported_rounded, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      // Huy hiệu thời gian tự hủy góc dưới (nếu đã mở diện mạo)
                      if (canViewIdentity && !item.isExpired)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.white, size: 10),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    item.remainingTimeFormatted,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Lớp Kính Mờ Blur nếu diện mạo bị khóa
                      if (!canViewIdentity)
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.35),
                            child: const Center(
                              child: Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}