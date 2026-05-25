import 'package:flutter/material.dart';
import '../../widgets/back.dart';
import '../../../core/utils/toast_utils.dart';

class SettingsSwitchAccountScreen extends StatefulWidget {
  const SettingsSwitchAccountScreen({super.key});

  @override
  State<SettingsSwitchAccountScreen> createState() => _SettingsSwitchAccountScreenState();
}

class _SettingsSwitchAccountScreenState extends State<SettingsSwitchAccountScreen> {
  // State lưu id tài khoản đang được chọn
  String _currentAccountId = '1';

  // Mock data danh sách tài khoản
  final List<Map<String, dynamic>> _accounts = [
    {
      'id': '1',
      'name': 'Peggy2402',
      'username': '@peggy.dev',
      'avatar': 'https://i.pravatar.cc/150?u=peggy',
    },
    {
      'id': '2',
      'name': 'Trần Phương',
      'username': '@phuong.tran',
      'avatar': 'https://i.pravatar.cc/150?u=phuong',
    },
  ];

  void _switchAccount(String id, String name) {
    if (_currentAccountId == id) return; // Không làm gì nếu đang chọn sẵn

    // Giả lập hiệu ứng Loading chuyển tài khoản
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      ),
    );

    // Sau 1 giây thì đóng loading, cập nhật state và hiện Toast
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // Đóng Loading
      setState(() {
        _currentAccountId = id;
      });
      ToastUtil.showSuccess(context, 'Đã chuyển sang tài khoản $name');
    });
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
          child: CustomBackButton(),
        ),
        title: const Text(
          'Chuyển đổi tài khoản',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ..._accounts.map((account) {
            final isCurrent = account['id'] == _currentAccountId;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFFF8FAFF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent ? const Color(0xFF4F46E5) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(account['avatar']),
                ),
                title: Text(
                  account['name'],
                  style: TextStyle(fontSize: 16, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
                subtitle: Text(
                  account['username'],
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 28) : null,
                onTap: () => _switchAccount(account['id'], account['name']),
              ),
            );
          }), // Xóa `.toList()` không cần thiết vì dùng toán tử spread `...`

          const SizedBox(height: 16),

          // Nút Thêm tài khoản
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFF4F46E5), size: 28),
              ),
              title: const Text(
                'Thêm tài khoản',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
              ),
              onTap: () {
                ToastUtil.showInfo(context, 'Chức năng thêm tài khoản đang phát triển');
              },
            ),
          ),
        ],
      ),
    );
  }
}