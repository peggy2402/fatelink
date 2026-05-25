import 'package:flutter/material.dart';
import '../../widgets/back.dart';

class SettingsListBlockScreen extends StatefulWidget {
  const SettingsListBlockScreen({super.key});

  @override
  State<SettingsListBlockScreen> createState() => _SettingsListBlockScreenState();
}

class _SettingsListBlockScreenState extends State<SettingsListBlockScreen> {
  // Mock data danh sách chặn
  final List<Map<String, String>> _blockedUsers = [
    {
      'id': '1',
      'name': 'Người Dấu Tên',
      'avatar': 'https://i.pravatar.cc/150?u=1',
      'date': '12/10/2023',
    },
    {
      'id': '2',
      'name': 'Cô Gái Bí Ẩn',
      'avatar': 'https://i.pravatar.cc/150?u=2',
      'date': '05/11/2023',
    },
    {
      'id': '3',
      'name': 'Chàng Trai Tháng Mười',
      'avatar': 'https://i.pravatar.cc/150?u=3',
      'date': '20/12/2023',
    },
  ];

  // Hàm giả lập "Bỏ chặn"
  void _unblockUser(String id) {
    setState(() {
      _blockedUsers.removeWhere((user) => user['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã bỏ chặn người dùng này'),
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
          child: CustomBackButton(), // Tái sử dụng CustomBackButton của bạn
        ),
        title: const Text(
          'Danh sách chặn',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _blockedUsers.isEmpty
          ? const Center(
              child: Text(
                'Bạn chưa chặn ai cả.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(user['avatar']!),
                    ),
                    title: Text(
                      user['name']!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    subtitle: Text(
                      'Đã chặn: ${user['date']}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _unblockUser(user['id']!),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Bỏ chặn', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}