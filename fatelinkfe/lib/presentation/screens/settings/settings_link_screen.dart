import 'package:flutter/material.dart';
import '../../widgets/back.dart';
import '../../../core/utils/toast_utils.dart';

class SettingsLinkScreen extends StatefulWidget {
  const SettingsLinkScreen({super.key});

  @override
  State<SettingsLinkScreen> createState() => _SettingsLinkScreenState();
}

class _SettingsLinkScreenState extends State<SettingsLinkScreen> {
  // Mock data danh sách các tài khoản liên kết
  final List<Map<String, dynamic>> _socialLinks = [
    {
      'id': 'google',
      'name': 'Google',
      'username': 'nguyenvana@gmail.com',
      'isLinked': true,
      'icon': Icons.g_mobiledata_rounded,
      'color': const Color(0xFFDB4437), // Đỏ Google
    },
    {
      'id': 'facebook',
      'name': 'Facebook',
      'username': '',
      'isLinked': false,
      'icon': Icons.facebook_rounded,
      'color': const Color(0xFF1877F2), // Xanh Facebook
    },
    {
      'id': 'apple',
      'name': 'Apple',
      'username': '',
      'isLinked': false,
      'icon': Icons.apple_rounded,
      'color': Colors.black, // Đen Apple
    },
    {
      'id': 'instagram',
      'name': 'Instagram',
      'username': '@nguyenvana',
      'isLinked': true,
      'icon': Icons.camera_alt_rounded,
      'color': const Color(0xFFE1306C), // Hồng Instagram
    },
    {
      'id': 'tiktok',
      'name': 'TikTok',
      'username': '@nguyenvana',
      'isLinked': true,
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFFE1306C), // Hồng Instagram
    },
  ];

  void _toggleLink(int index) {
    final item = _socialLinks[index];
    final isLinked = item['isLinked'] as bool;

    setState(() {
      _socialLinks[index]['isLinked'] = !isLinked;
      if (!isLinked) {
        // Giả lập lấy username sau khi liên kết
        _socialLinks[index]['username'] = 'Đã liên kết mới'; 
      } else {
        _socialLinks[index]['username'] = '';
      }
    });

    if (isLinked) {
      ToastUtil.showInfo(context, 'Đã hủy liên kết với ${item['name']}');
    } else {
      ToastUtil.showSuccess(context, 'Đã liên kết thành công với ${item['name']}');
    }
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
          'Tài khoản liên kết',
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
        itemCount: _socialLinks.length,
        itemBuilder: (context, index) {
          final link = _socialLinks[index];
          final bool isLinked = link['isLinked'];

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
                backgroundColor: (link['color'] as Color).withOpacity(0.1),
                child: Icon(link['icon'], color: link['color'], size: 28),
              ),
              title: Text(
                link['name'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              subtitle: Text(
                isLinked ? link['username'] : 'Chưa liên kết',
                style: TextStyle(fontSize: 13, color: isLinked ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
              ),
              trailing: ElevatedButton(
                onPressed: () => _toggleLink(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLinked ? const Color(0xFFF1F5F9) : const Color(0xFF4F46E5),
                  foregroundColor: isLinked ? const Color(0xFF475569) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  isLinked ? 'Hủy' : 'Liên kết',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}