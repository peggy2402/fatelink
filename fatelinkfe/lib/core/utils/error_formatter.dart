import 'dart:convert';

/// Tiện ích làm sạch và định dạng thông điệp lỗi trước khi hiển thị lên giao diện (UI)
/// Đảm bảo không để lộ các thông tin kỹ thuật như raw JSON, exception stack, hoặc mã lỗi nội bộ.
class ErrorFormatter {
  static String format(dynamic error) {
    if (error == null) return 'Đã có lỗi xảy ra. Vui lòng thử lại!';

    String raw = error.toString().trim();

    // Bỏ tiền tố Exception:
    if (raw.startsWith('Exception:')) {
      raw = raw.replaceFirst('Exception:', '').trim();
    }

    // Bỏ tiền tố Lỗi:
    if (raw.startsWith('Lỗi:')) {
      raw = raw.replaceFirst('Lỗi:', '').trim();
    }

    // Kiểm tra lỗi mất mạng
    if (raw.contains('NO_INTERNET_CONNECTION') ||
        raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network is unreachable')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra lại Wifi/4G!';
    }

    // Kiểm tra lỗi timeout
    if (raw.contains('TimeoutException') || raw.contains('timed out')) {
      return 'Kết nối máy chủ quá thời gian. Vui lòng thử lại!';
    }

    // Kiểm tra nếu trong raw có chứa JSON backend (ví dụ {"statusCode":500,"message":"..."})
    final jsonStartIndex = raw.indexOf('{');
    final jsonEndIndex = raw.lastIndexOf('}');
    if (jsonStartIndex != -1 &&
        jsonEndIndex != -1 &&
        jsonEndIndex > jsonStartIndex) {
      final jsonCandidate = raw.substring(jsonStartIndex, jsonEndIndex + 1);
      try {
        final decoded = jsonDecode(jsonCandidate);
        if (decoded is Map<String, dynamic>) {
          final serverMsg = decoded['message'];
          final errorCode = decoded['errorCode']?.toString();
          final statusCode = decoded['statusCode'];

          if (errorCode == 'AUTH_GOOGLE_PROFILE_ORPHANED' ||
              statusCode == 500) {
            return 'Đăng nhập Google thất bại. Vui lòng thử lại sau ít phút!';
          }

          if (serverMsg is String && serverMsg.isNotEmpty) {
            return _friendlyServerMessage(serverMsg);
          } else if (serverMsg is List && serverMsg.isNotEmpty) {
            return _friendlyServerMessage(serverMsg.first.toString());
          }
        }
      } catch (_) {
        // Không parse được JSON, tiếp tục xử lý chuỗi
      }
    }

    // Nếu chứa mã lỗi Server 500
    if (raw.contains('500') ||
        raw.contains('Internal Server Error') ||
        raw.contains('INTERNAL')) {
      return 'Máy chủ đang bận xử lý. Vui lòng thử lại sau ít phút!';
    }

    // Nếu chuỗi chứa "Xác thực thất bại:"
    if (raw.startsWith('Xác thực thất bại:')) {
      return 'Đăng nhập không thành công. Vui lòng thử lại!';
    }

    return raw;
  }

  static String _friendlyServerMessage(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('invalid credentials') ||
        lower.contains('wrong password') ||
        lower.contains('mật khẩu không đúng')) {
      return 'Tài khoản hoặc mật khẩu không chính xác.';
    }
    if (lower.contains('user not found') ||
        lower.contains('không tìm thấy người dùng')) {
      return 'Tài khoản không tồn tại trên hệ thống.';
    }
    if (lower.contains('email already exists') ||
        lower.contains('đã tồn tại')) {
      return 'Email hoặc tài khoản này đã được đăng ký.';
    }
    if (lower.contains('token expired') ||
        lower.contains('phiên đăng nhập hết hạn')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (lower.contains('missing user') || lower.contains('orphaned')) {
      return 'Tài khoản đang được đồng bộ lại. Vui lòng thử đăng nhập lại!';
    }
    return msg;
  }
}
