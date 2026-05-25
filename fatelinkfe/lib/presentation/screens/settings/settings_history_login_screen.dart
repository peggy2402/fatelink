import 'package:flutter/material.dart';
import '../../widgets/back.dart';

class SettingsHistoryLoginScreen extends StatelessWidget {
  const SettingsHistoryLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data lịch sử đăng nhập
    final List<Map<String, dynamic>> _loginHistory = [
      {
        'device': 'iPhone 15 Pro Max',
        'location': 'Hà Nội, Việt Nam',
        'time': 'Vừa xong',
        'ip': '113.190.23.120',
        'isCurrent': true,
        'icon': Icons.phone_iphone_rounded,
      },
      {
        'device': 'Chrome trên Windows',
        'location': 'Hồ Chí Minh, Việt Nam',
        'time': 'Hôm qua, 14:30',
        'ip': '14.161.45.99',
        'isCurrent': false,
        'icon': Icons.laptop_windows_rounded,
      },
      {
        'device': 'Safari trên macOS',
        'location': 'Đà Nẵng, Việt Nam',
        'time': '12/10/2023, 09:15',
        'ip': '171.248.19.45',
        'isCurrent': false,
        'icon': Icons.laptop_mac_rounded,
      },
    ];

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
          'Lịch sử đăng nhập',
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
        itemCount: _loginHistory.length,
        itemBuilder: (context, index) {
          final item = _loginHistory[index];
          return Container(
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
                child: Icon(item['icon'], color: const Color(0xFF4F46E5), size: 24),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['device'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ),
                  if (item['isCurrent'])
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
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(item['location'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(item['time'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}