import 'package:flutter/material.dart';
import '../../widgets/back.dart';

class SettingsManageDeviceScreen extends StatefulWidget {
  const SettingsManageDeviceScreen({super.key});

  @override
  State<SettingsManageDeviceScreen> createState() => _SettingsManageDeviceScreenState();
}

class _SettingsManageDeviceScreenState extends State<SettingsManageDeviceScreen> {
  // Mock data danh sách thiết bị
  final List<Map<String, dynamic>> _devices = [
    {
      'id': '1',
      'name': 'iPhone 15 Pro Max',
      'status': 'Đang hoạt động',
      'isCurrent': true,
      'icon': Icons.phone_iphone_rounded,
    },
    {
      'id': '2',
      'name': 'Chrome trên Windows',
      'status': 'Hoạt động 2 giờ trước',
      'isCurrent': false,
      'icon': Icons.laptop_windows_rounded,
    },
    {
      'id': '3',
      'name': 'Safari trên macOS',
      'status': 'Hoạt động 5 ngày trước',
      'isCurrent': false,
      'icon': Icons.laptop_mac_rounded,
    },
  ];

  // Hàm giả lập "Đăng xuất" thiết bị
  void _logoutDevice(String id) {
    setState(() {
      _devices.removeWhere((device) => device['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đăng xuất thiết bị thành công'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(6.0),
          child: CustomBackButton(), // Gọi lại nút back dùng chung
        ),
        title: const Text(
          'Quản lý thiết bị',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return Dismissible(
            key: Key(device['id']),
            // Không cho phép vuốt xoá thiết bị "Hiện tại"
            direction: device['isCurrent'] ? DismissDirection.none : DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
            onDismissed: (direction) => _logoutDevice(device['id']),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(device['icon'], color: const Color(0xFF4F46E5), size: 24),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        device['name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ),
                    if (device['isCurrent'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Hiện tại',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(device['status'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ),
                trailing: device['isCurrent']
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48)),
                        onPressed: () => _logoutDevice(device['id']),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}