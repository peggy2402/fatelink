import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:fatelinkfe/presentation/screens/login_screen.dart';

class ApiService {
  static const _secureStorage = FlutterSecureStorage();

  // Hàm hiển thị Loading Dialog
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFBD114A)),
      ),
    );
  }

  // Hàm ẩn Loading Dialog
  static void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Hàm xử lý response chung
  static dynamic _handleResponse(http.Response response, BuildContext context) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response
            .body; // Trả về dạng String nếu API không trả về chuẩn JSON
      }
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Xử lý Lỗi Auth: Token hết hạn hoặc không hợp lệ -> Xóa token và về trang Login
      _secureStorage.delete(key: 'accessToken');

      // Chuyển hướng về trang Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    } else {
      // Các lỗi khác (400, 404, 500...) -> Quăng lỗi dạng String thay vì parse JSON
      throw Exception('Lỗi Server: Mã ${response.statusCode}');
    }
  }

  // Phương thức GET dùng chung
  static Future<dynamic> get(
    String url,
    BuildContext context, {
    String? token,
    bool showLoading = false,
  }) async {
    if (showLoading) _showLoadingDialog(context);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response, context);
    } finally {
      if (showLoading) _hideLoadingDialog(context);
    }
  }

  // Phương thức POST dùng chung
  static Future<dynamic> post(
    String url,
    BuildContext context, {
    String? token,
    Object? body,
    bool showLoading = false,
  }) async {
    if (showLoading) _showLoadingDialog(context);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response, context);
    } finally {
      if (showLoading) _hideLoadingDialog(context);
    }
  }

  // Phương thức PUT dùng chung (Sử dụng cho tính năng Update)
  static Future<dynamic> put(
    String url,
    BuildContext context, {
    String? token,
    Object? body,
    bool showLoading = false,
  }) async {
    if (showLoading) _showLoadingDialog(context);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response, context);
    } finally {
      if (showLoading) _hideLoadingDialog(context);
    }
  }

  // Phương thức DELETE dùng chung
  static Future<dynamic> delete(
    String url,
    BuildContext context, {
    String? token,
    bool showLoading = false,
  }) async {
    if (showLoading) _showLoadingDialog(context);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.delete(Uri.parse(url), headers: headers);
      return _handleResponse(response, context);
    } finally {
      if (showLoading) _hideLoadingDialog(context);
    }
  }
}
