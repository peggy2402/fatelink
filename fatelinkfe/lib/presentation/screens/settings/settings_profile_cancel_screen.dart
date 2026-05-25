import 'package:flutter/material.dart';
import '../../widgets/back.dart';
import '../../../core/utils/toast_utils.dart';

class SettingsProfileCancelScreen extends StatefulWidget {
  const SettingsProfileCancelScreen({super.key});

  @override
  State<SettingsProfileCancelScreen> createState() => _SettingsProfileCancelScreenState();
}

class _SettingsProfileCancelScreenState extends State<SettingsProfileCancelScreen> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _showConfirmDialog() {
    // Đóng bàn phím (nếu đang mở) trước khi hiện Dialog
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Xác nhận hủy tài khoản',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          content: const Text(
            'Hành động này không thể hoàn tác. Mọi dữ liệu, lịch sử chat và các kết nối của bạn sẽ bị xóa vĩnh viễn. Bạn có chắc chắn muốn tiếp tục?',
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Đóng Dialog
                // Thực hiện logic gọi API hủy tài khoản tại đây
                ToastUtil.showSuccess(context, 'Tài khoản của bạn đã được lên lịch xóa.');
                // Ví dụ: Điều hướng về màn Login (Navigator.pushAndRemoveUntil)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(6.0),
          child: CustomBackButton(),
        ),
        title: const Text(
          'Hủy tài khoản',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2), // Đỏ nhạt
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sentiment_very_dissatisfied_rounded,
                size: 80,
                color: Color(0xFFE11D48), // Đỏ đậm
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chúng tôi rất tiếc khi bạn rời đi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Có điều gì khiến bạn không hài lòng về FateLink? Hãy để lại góp ý để chúng tôi cải thiện tốt hơn nhé!',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _feedbackController,
              maxLines: 5, // Khung nhập liệu rộng nhiều dòng
              decoration: InputDecoration(
                hintText: 'Nhập góp ý của bạn (không bắt buộc)...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showConfirmDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Gửi & Tiếp tục Hủy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}