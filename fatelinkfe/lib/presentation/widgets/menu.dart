import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppMenuDrawer extends StatefulWidget {
  const AppMenuDrawer({super.key});

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

  @override
  Widget build(BuildContext context) {
    // Nền của Drawer phải trong suốt để hiệu ứng blur hoạt động
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        // Bo góc bên trái vì Drawer trượt ra từ bên phải
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Giới hạn chiều rộng
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: Border(left: BorderSide(color: Colors.white.withOpacity(0.2))),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        _buildMenuListItem(
                          icon: Icons.settings_outlined,
                          title: 'Settings'.tr(),
                          onTap: () {},
                        ),
                        _buildMenuListItem(
                          icon: Icons.language_outlined,
                          title: 'Language'.tr(),
                          onTap: () {},
                        ),
                        _buildMenuListItem(
                          icon: Icons.share_outlined,
                          title: 'inviteFriends'.tr(),
                          onTap: () {},
                        ),
                        _buildMenuListItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Support'.tr(),
                          onTap: () {},
                        ),
                        _buildMenuListItem(
                          icon: Icons.description_outlined,
                          title: 'termsAndPolicies'.tr(),
                          onTap: () {},
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Colors.grey.shade300, height: 1, thickness: 1),
                        ),
                        _buildMenuListItem(
                          icon: Icons.logout_rounded,
                          title: 'Logout'.tr(),
                          onTap: () {
                            // context.read<AuthBloc>().add(AuthLogoutRequested());
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFC084FC), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(
                child: Image.network(
                  'https://api.dicebear.com/7.x/adventurer/png?seed=Luna&backgroundColor=f3e8ff',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mưa Đêm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text('ID: #8821_SOUL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF475569)),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close Menu',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuListItem({required IconData icon, required String title, required VoidCallback onTap, bool isDanger = false}) {
    final color = isDanger ? const Color(0xFFE11D48) : const Color(0xFF4F46E5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDanger ? color : const Color(0xFF334155))),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
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
          _appVersion.isEmpty ? 'FateLink' : 'FateLink $_appVersion',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }
}