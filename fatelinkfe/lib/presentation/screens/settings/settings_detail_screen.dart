import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/back.dart';
import '../../widgets/settings_interface_bottom_sheet.dart';
import '../../widgets/settings_match_bottom_sheet.dart';
import '../../widgets/settings_distance_bottom_sheet.dart';
import 'settings_list_block_screen.dart'; // Import trang danh sách chặn
import 'settings_history_login_screen.dart'; // Import trang lịch sử đăng nhập
import 'settings_manage_device_screen.dart'; // Import trang quản lý thiết bị
import 'settings_profile_cancel_screen.dart'; // Import trang hủy tài khoản
import 'settings_link_screen.dart'; // Import trang liên kết
import 'settings_about_us_screen.dart'; // Import trang Về chúng tôi
import 'settings_switch_account_screen.dart'; // Import trang Chuyển đổi tài khoản
import '../../../core/utils/toast_utils.dart'; // Import ToastUtil

class SettingsDetailScreen extends StatefulWidget {
  const SettingsDetailScreen({super.key});

  @override
  State<SettingsDetailScreen> createState() => _SettingsDetailScreenState();
}

class _SettingsDetailScreenState extends State<SettingsDetailScreen> {
  // Các trạng thái (States) cho các tuỳ chọn cài đặt
  bool _biometricLogin = true;
  String _themeMode = 'Hệ thống';
  String _matchGender = 'All';

  // Thông báo
  bool _dnd24h = false;
  bool _fayeAiMsg = true;
  bool _matchRequest = true;
  bool _sysNotification = true;

  // An toàn
  bool _filterSensitiveContent = true;

  // Quyền riêng tư
  bool _hideLocation = false;
  bool _hideGenderAge = false;
  bool _disablePersonalization = false;
  bool _showProfile = true;
  bool _activeStatus = true;
  String _showDistance = 'Hiện khoảng cách chính xác';
  
  // State lưu dung lượng bộ nhớ cache
  String _cacheSize = '124 MB';

  void _openInterfaceBottomSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SettingsInterfaceBottomSheet(currentValue: _themeMode),
    );
    if (result != null && mounted) setState(() => _themeMode = result);
  }

  void _openMatchGenderBottomSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SettingsMatchBottomSheet(currentValue: _matchGender),
    );
    if (result != null && mounted) setState(() => _matchGender = result);
  }

  void _openDistanceBottomSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SettingsDistanceBottomSheet(currentValue: _showDistance),
    );
    if (result != null && mounted) setState(() => _showDistance = result);
  }

  // Hàm hiển thị Popup (Dialog) xác nhận xóa cache
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Xóa bộ nhớ cache', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          content: const Text(
            'Bạn có chắc chắn muốn xóa toàn bộ bộ nhớ cache không? Việc này sẽ giải phóng dung lượng nhưng có thể làm ứng dụng tải lại dữ liệu lâu hơn ở lần tiếp theo.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Đóng popup
                setState(() {
                  _cacheSize = '0 MB'; // Cập nhật dung lượng về 0
                });
                ToastUtil.showSuccess(context, 'Đã xóa bộ nhớ cache thành công');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48), // Màu đỏ cảnh báo
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Nền màu xám nhạt tinh tế
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(6.0), // Căn lề nhẹ để CustomBackButton (44x44) nằm vừa vặn
          child: CustomBackButton(),
        ),
        title: Text(
          'Settings'.tr(),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Tài khoản & Giao diện'),
          _buildSwitchTile(
            title: 'Đăng nhập bằng vân tay / khuôn mặt',
            icon: Icons.fingerprint_rounded,
            value: _biometricLogin,
            onChanged: (val) => setState(() => _biometricLogin = val),
          ),
          _buildBottomSheetTile(
            title: 'Giao diện',
            icon: Icons.brightness_6_outlined,
            value: _themeMode,
            onTap: _openInterfaceBottomSheet,
          ),

          _buildSectionHeader('Ghép nối & Khám phá'),
          _buildBottomSheetTile(
            title: 'Giới tính ghép nối',
            icon: Icons.people_alt_outlined,
            value: _matchGender,
            onTap: _openMatchGenderBottomSheet,
          ),

          _buildSectionHeader('Thông báo'),
          _buildSwitchTile(
            title: 'Không làm phiền trong 24 giờ',
            icon: Icons.notifications_off_outlined,
            value: _dnd24h,
            onChanged: (val) => setState(() => _dnd24h = val),
          ),
          _buildSwitchTile(
            title: 'Tin nhắn Faye AI',
            icon: Icons.auto_awesome_outlined,
            value: _fayeAiMsg,
            onChanged: (val) => setState(() => _fayeAiMsg = val),
          ),
          _buildSwitchTile(
            title: 'Lời mời/Yêu cầu ghép nối',
            icon: Icons.favorite_border_rounded,
            value: _matchRequest,
            onChanged: (val) => setState(() => _matchRequest = val),
          ),
          _buildSwitchTile(
            title: 'Thông báo hệ thống',
            icon: Icons.info_outline_rounded,
            value: _sysNotification,
            onChanged: (val) => setState(() => _sysNotification = val),
          ),

          _buildSectionHeader('Chặn & An toàn'),
          _buildActionTile(
            title: 'Danh sách chặn',
            icon: Icons.block_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsListBlockScreen(),
                ),
              );
            },
          ),
          _buildSwitchTile(
            title: 'Lọc nội dung nhạy cảm',
            icon: Icons.security_rounded,
            value: _filterSensitiveContent,
            onChanged: (val) => setState(() => _filterSensitiveContent = val),
          ),

          _buildSectionHeader('Quyền riêng tư'),
          _buildSwitchTile(
            title: 'Ẩn vị trí chính xác của tôi',
            icon: Icons.location_off_outlined,
            value: _hideLocation,
            onChanged: (val) => setState(() => _hideLocation = val),
          ),
          _buildSwitchTile(
            title: 'Ẩn giới tính/tuổi của tôi',
            icon: Icons.visibility_off_outlined,
            value: _hideGenderAge,
            onChanged: (val) => setState(() => _hideGenderAge = val),
          ),
          _buildSwitchTile(
            title: 'Tắt đề xuất cá nhân hóa',
            icon: Icons.person_off_outlined,
            value: _disablePersonalization,
            onChanged: (val) => setState(() => _disablePersonalization = val),
          ),
          _buildSwitchTile(
            title: 'Hiển thị hồ sơ',
            icon: Icons.badge_outlined,
            value: _showProfile,
            onChanged: (val) => setState(() => _showProfile = val),
          ),
          _buildSwitchTile(
            title: 'Trạng thái hoạt động',
            icon: Icons.online_prediction_rounded,
            value: _activeStatus,
            onChanged: (val) => setState(() => _activeStatus = val),
          ),
          _buildBottomSheetTile(
            title: 'Hiển thị khoảng cách',
            icon: Icons.map_outlined,
            value: _showDistance,
            onTap: _openDistanceBottomSheet,
          ),

          _buildSectionHeader('Trung tâm bảo mật'),
          _buildActionTile(
            title: 'Lịch sử đăng nhập',
            icon: Icons.history_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsHistoryLoginScreen(),
                ),
              );
            },
          ),
          _buildActionTile(
            title: 'Quản lý thiết bị',
            icon: Icons.devices_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsManageDeviceScreen(),
                ),
              );
            },
          ),
          _buildActionTile(
            title: 'Hủy tài khoản',
            icon: Icons.delete_forever_rounded,
            isDestructive: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsProfileCancelScreen(),
                ),
              );
            },
          ),

          _buildSectionHeader('Khác'),
          _buildActionTile(
            title: 'Liên kết',
            icon: Icons.link_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsLinkScreen(),
                ),
              );
            },
          ),
          _buildActionTile(
            title: 'Xóa bộ nhớ cache',
            icon: Icons.cleaning_services_rounded,
            trailingText: _cacheSize, // Hiển thị state dung lượng cache
            onTap: _showClearCacheDialog,
          ),
          _buildActionTile(
            title: 'Về chúng tôi',
            icon: Icons.info_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsAboutUsScreen(),
                ),
              );
            },
          ),
          _buildActionTile(
            title: 'Chuyển đổi tài khoản',
            icon: Icons.swap_horiz_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsSwitchAccountScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 40), // Spacing ở cuối
        ],
      ),
    );
  }

  // --- Các UI Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B), // Slate 500
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF4F46E5)), // Indigo
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
        ),
        activeColor: const Color(0xFF4F46E5),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBottomSheetTile({
    required String title,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4F46E5)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 22),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? trailingText,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFE11D48) : const Color(0xFF1E293B);
    final iconColor = isDestructive ? const Color(0xFFE11D48) : const Color(0xFF4F46E5);

    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
        trailing: trailingText != null
            ? Text(trailingText, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)))
            : Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
        onTap: onTap,
      ),
    );
  }
}