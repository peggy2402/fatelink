import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fatelinkfe/data/models/match_user.dart';
import 'package:fatelinkfe/presentation/screens/match/match_chat_screen.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/responsive/responsive.dart';
import '../../widgets/cosmic_pulse_received_modal.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../services/api_service.dart';
import '../../widgets/cosmic_report_modal.dart';
import 'widgets/user_detail_app_bar.dart';
import 'widgets/user_detail_avatar_card.dart';
import 'widgets/user_detail_stats_card.dart';
import 'widgets/user_detail_compatibility_card.dart';
import 'widgets/user_detail_vibe_gallery.dart';
import 'widgets/user_detail_info_card.dart';
import 'widgets/user_detail_bottom_bar.dart';

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
      if (!mounted) return;
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
      if (!mounted) return;
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
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSendWave(String displayName) async {
    HapticFeedback.mediumImpact();
    setState(() => _isWaveSent = true);

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (!mounted) return;
      if (token != null &&
          widget.user.id.isNotEmpty &&
          !widget.user.id.startsWith('echo-')) {
        final url =
            '${AppConstants.baseUrl}/${AppConstants.userRecordWave(widget.user.id)}';
        await ApiService.post(url, context, token: token);
      }
    } catch (_) {}

    if (mounted) {
      CosmicPulseReceivedModal.show(context, sender: widget.user);
    }
  }

  Future<void> _handleBlockUser() async {
    final displayName = canViewIdentity
        ? widget.user.name
        : widget.user.anonymousName;

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
                borderRadius: BorderRadius.circular(10),
              ),
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
    final displayName = canViewIdentity
        ? widget.user.name
        : widget.user.anonymousName;

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
              leading: const Icon(
                Icons.flag_outlined,
                color: Color(0xFFF59E0B),
              ),
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
              leading: const Icon(
                Icons.block_rounded,
                color: Color(0xFFEF4444),
              ),
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

    final distance = widget.user.distanceKm != null
        ? '${widget.user.distanceKm} km'
        : 'Gần bạn';
    final tags = (widget.user.tags != null && widget.user.tags!.isNotEmpty)
        ? widget.user.tags!
        : ['#NhạcIndie', '#ĐêmMuộn', '#DeepTalk'];

    final vibePhotos =
        (widget.user.vibePhotos != null && widget.user.vibePhotos!.isNotEmpty)
            ? widget.user.vibePhotos!
            : defaultVibePhotos;

    final displayName = canViewIdentity
        ? widget.user.name
        : widget.user.anonymousName;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.15,
        child: Stack(
          children: [
            // Ambient mesh background gradient
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
                    UserDetailAppBar(
                      canViewIdentity: canViewIdentity,
                      onBack: () => Navigator.of(context).pop(),
                      onOptionsTap: _showUserOptionsModal,
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          10,
                          20,
                          100 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            UserDetailAvatarCard(
                              user: widget.user,
                              canViewIdentity: canViewIdentity,
                              displayName: displayName,
                              distance: distance,
                              tags: tags,
                            ),

                            const SizedBox(height: 20),

                            UserDetailStatsCard(
                              isFollowing: _isFollowing,
                              likesCount: _likesCount,
                              compatibilityScore: widget.user.compatibilityScore,
                            ),

                            UserDetailCompatibilityCard(
                              score: widget.user.compatibilityScore,
                              displayName: displayName,
                            ),

                            const SizedBox(height: 20),

                            UserDetailVibeGallery(
                              photos: vibePhotos,
                              canViewIdentity: canViewIdentity,
                              isFaceLocked: widget.user.isFaceLocked,
                            ),

                            const SizedBox(height: 18),

                            UserDetailInfoCard(
                              title: 'Trạng thái tần số',
                              value:
                                  '${widget.user.moodIcon != null ? "${widget.user.moodIcon} " : ""}${widget.user.emotion}',
                              icon: Icons.graphic_eq_rounded,
                              color: const Color(0xFF8B5CF6),
                            ),
                            UserDetailInfoCard(
                              title: 'Nhu cầu kết nối',
                              value: widget.user.bio ??
                                  'Chia sẻ chân thành, lắng nghe sâu',
                              icon: Icons.chat_bubble_outline_rounded,
                              color: primaryColor,
                            ),
                            UserDetailInfoCard(
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

            // Floating Bottom Bar
            UserDetailBottomBar(
              isFollowing: _isFollowing,
              isMutualFollow: _isMutualFollow,
              isWaveSent: _isWaveSent,
              onToggleFollow: _toggleFollow,
              onPrimaryAction: () {
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
            ),
          ],
        ),
      ),
    );
  }
}
