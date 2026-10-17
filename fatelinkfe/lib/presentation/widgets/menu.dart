import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../screens/settings/settings_detail_screen.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../../logic/blocs/auth/auth_event.dart';
import '../../logic/blocs/profile/profile_bloc.dart';
import '../../logic/blocs/profile/profile_state.dart';
import '../../core/utils/slug_utils.dart';
import '../../core/services/image_picker_service.dart';
import '../screens/profile/widgets/profile_share_card_modal.dart';

class AppMenuDrawer extends StatefulWidget {
  final VoidCallback? onClose;

  const AppMenuDrawer({super.key, this.onClose});

  @override
  State<AppMenuDrawer> createState() => _AppMenuDrawerState();
}

class _AppMenuDrawerState extends State<AppMenuDrawer> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${info.version}';
        });
      }
    } catch (e) {
      // Bỏ qua lỗi nếu không lấy được phiên bản
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'chooseLanguage'.tr(),
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
              title: const Text(
                'Tiếng Việt',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: context.locale.languageCode == 'vi'
                  ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
                  : null,
              onTap: () {
                context.setLocale(const Locale('vi'));
                Navigator.pop(bottomSheetContext);
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text(
                'English',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: context.locale.languageCode == 'en'
                  ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
                  : null,
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(bottomSheetContext);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 10),
            Text(
              'termsAndPolicies'.tr(),
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Cam kết bảo mật Meyu Soul:',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Thông tin cá nhân và định danh của bạn luôn được mã hóa an toàn.\n'
                '2. Bạn có toàn quyền bật Chế độ ẩn danh (Khóa diện mạo) để bảo vệ khuôn mặt.\n'
                '3. Ảnh Vibe Corner tự hủy sau thời gian hẹn giờ.\n'
                '4. Meyu không bao giờ chia sẻ dữ liệu riêng tư cho bên thứ ba.',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          width: math.min(screenWidth * 0.82, 340.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            border: Border(
              left: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    children: [
                      _buildMenuListItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings'.tr(),
                        onTap: () {
                          widget.onClose?.call();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SettingsDetailScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuListItem(
                        icon: Icons.language_outlined,
                        title: 'Language'.tr(),
                        onTap: () => _showLanguageSelector(context),
                      ),
                      _buildMenuListItem(
                        icon: Icons.share_outlined,
                        title: 'inviteFriends'.tr(),
                        onTap: () {
                          final state = context.read<ProfileBloc>().state;
                          String currentName = 'Meyu Soul';
                          String currentAvatar = '';
                          String currentHandle = '';

                          if (state is ProfileLoaded) {
                            currentName = state.profileData['name'] ?? 'Meyu Soul';
                            currentAvatar = state.profileData['avatar'] ?? '';
                            currentHandle = state.profileData['handle'] ?? currentName;
                          }

                          widget.onClose?.call();
                          ProfileShareCardModal.show(
                            context,
                            name: currentName,
                            handle: SlugUtils.toDisplayHandle(currentHandle),
                            soulId: SlugUtils.toCleanHandle(currentHandle),
                            avatar: currentAvatar,
                          );
                        },
                      ),
                      _buildMenuListItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Support'.tr(),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                'Trung tâm hỗ trợ Meyu',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                'Cần trợ giúp hoặc phản hồi lỗi?\nEmail: support@meyu.com\nĐội ngũ Meyu luôn đồng hành cùng bạn 24/7.',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                  height: 1.4,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text('Đóng'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildMenuListItem(
                        icon: Icons.description_outlined,
                        title: 'termsAndPolicies'.tr(),
                        onTap: () => _showTermsDialog(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(
                          color: Colors.grey.shade300,
                          height: 1,
                          thickness: 1,
                        ),
                      ),
                      _buildMenuListItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout'.tr(),
                        onTap: () {
                          widget.onClose?.call();
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                        isDanger: true,
                      ),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        String displayName = 'Người dùng Meyu';
        String rawHandle = '';
        String avatarUrl = '';

        if (state is ProfileLoaded) {
          final data = state.profileData;
          displayName = data['name'] ?? data['displayName'] ?? 'Người dùng Meyu';
          rawHandle = data['handle'] ?? data['name'] ?? '';
          avatarUrl = (data['avatar'] ?? '').toString();
        }

        // 100% tiếng Anh không dấu, chuẩn định dạng mạng xã hội
        final cleanDisplayHandle = SlugUtils.toDisplayHandle(
          rawHandle.isNotEmpty ? rawHandle : displayName,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC084FC), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image(
                    image: ImagePickerService.getImageProvider(avatarUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE0E7FF),
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF4F46E5),
                            size: 26,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Handle 100% không dấu (loại bỏ hoàn toàn ID: # thừa thãi)
                    Text(
                      cleanDisplayHandle,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF475569)),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: const EdgeInsets.all(8),
                onPressed: () => widget.onClose?.call(),
                tooltip: 'Close Menu',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? const Color(0xFFE11D48) : const Color(0xFF4F46E5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDanger
                          ? [const Color(0xFFFB7185), const Color(0xFFF43F5E)]
                          : [const Color(0xFF818CF8), const Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? color : const Color(0xFF334155),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, top: 10),
      child: Center(
        child: Text(
          _appVersion.isEmpty ? 'Meyu' : 'Meyu $_appVersion',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}