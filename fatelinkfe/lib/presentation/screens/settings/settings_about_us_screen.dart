import 'package:flutter/material.dart';
import '../../widgets/back.dart';

class SettingsAboutUsScreen extends StatelessWidget {
  const SettingsAboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(6.0),
          child: CustomBackButton(), // Tái sử dụng CustomBackButton
        ),
        title: const Text(
          'Về chúng tôi',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Logo của App
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: const Center(
                child: Icon(Icons.favorite_rounded, size: 50, color: Color(0xFF4F46E5)), // Thay bằng Image.asset nếu có logo thật
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FateLink',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Phiên bản 1.0.0',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 40),

            // Danh sách các Menu chức năng
            _buildLinkItem(context, 'Điều khoản sử dụng', Icons.description_outlined),
            _buildLinkItem(context, 'Chính sách bảo mật', Icons.privacy_tip_outlined),
            _buildLinkItem(context, 'Đánh giá ứng dụng', Icons.star_border_rounded),
            _buildLinkItem(context, 'Website chính thức', Icons.language_rounded),

            const SizedBox(height: 40),
            const Text(
              '© 2024 FateLink. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: const Color(0xFF4F46E5)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: () {}, // Thêm hành động mở URL / Webview vào đây sau này
      ),
    );
  }
}