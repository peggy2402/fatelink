import 'package:flutter/material.dart';
import 'package:fatelinkfe/data/models/match_user.dart';
import 'package:easy_localization/easy_localization.dart';

class UserDetailScreen extends StatelessWidget {
  final MatchUser user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Màu sắc phong cách Light Mode sạch sẽ
    const Color primaryColor = Color(0xFF0066FF);
    const Color backgroundColor = Color(0xFFF8FAFC);
    const Color cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'compatibilityProfile'.tr(),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 75,
                backgroundImage: AssetImage('assets/images/avt_faye_ai.png'),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${'emotionalFrequency'.tr()}: ${user.emotion}',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Các thẻ thông tin
            _buildDetailCard(
              title: 'Mức độ tương hợp',
              value: '${90 + user.id.hashCode % 10}%',
              icon: Icons.favorite,
              color: Colors.redAccent,
            ),
            _buildDetailCard(
              title: 'Trạng thái hiện tại',
              value: user.emotion,
              icon: Icons.mood,
              color: Colors.amber,
            ),
            _buildDetailCard(
              title: 'Phong cách giao tiếp',
              value: 'Cởi mở, chân thành',
              icon: Icons.chat_bubble_outline,
              color: primaryColor,
            ),
            const SizedBox(height: 20),
            
            // Nút hành động
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Bắt đầu trò chuyện', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
        ],
      ),
    );
  }
}