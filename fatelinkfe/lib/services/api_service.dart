import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fatelinkfe/presentation/screens/login/login_screen.dart';
import 'package:fatelinkfe/core/utils/constants.dart';
import 'package:fatelinkfe/core/utils/device_id_helper.dart';
import 'package:fatelinkfe/core/utils/secure_storage_helper.dart';
import 'package:fatelinkfe/core/services/network_connectivity_service.dart';
import 'package:fatelinkfe/core/network/http_logger.dart';
import 'package:fatelinkfe/core/utils/error_formatter.dart';

class ApiService {
  static const _secureStorage = SecureStorageHelper.storage;

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

  /// Trích xuất thông điệp lỗi nghiệp vụ từ response body nếu có
  static String _extractErrorMessage(http.Response response) {
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final msg = decoded['message'];
          if (msg is List && msg.isNotEmpty) {
            return msg.first.toString();
          }
          if (msg != null && msg.toString().isNotEmpty) {
            return msg.toString();
          }
        }
      } catch (_) {}
    }
    return 'Lỗi Server: Mã ${response.statusCode}';
  }

  // Hàm xử lý response chung
  static dynamic _handleResponse(http.Response response, BuildContext context) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body; // Trả về dạng String nếu API không trả về chuẩn JSON
      }
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Xử lý Lỗi Auth: Token hết hạn hoặc không hợp lệ -> Xóa token và về trang Login
      _secureStorage.delete(key: 'accessToken');
      _secureStorage.delete(key: 'refreshToken');

      // Chuyển hướng về trang Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    } else {
      final msg = _extractErrorMessage(response);
      throw Exception(ErrorFormatter.format(msg));
    }
  }

  static dynamic _handleResponseWithoutContext(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }

    final msg = _extractErrorMessage(response);
    throw Exception(ErrorFormatter.format(msg));
  }

  /// Thực thi request kèm ghi log URL API + REQUEST + RESPONSE ra Debug Console
  static Future<http.Response> executeWithLogging({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
    required Future<http.Response> Function() requestFn,
  }) async {
    HttpLogger.logRequest(
      method: method,
      url: uri,
      headers: headers,
      body: body,
    );

    final stopwatch = Stopwatch()..start();
    try {
      final response = await requestFn();
      stopwatch.stop();
      HttpLogger.logResponse(
        method: method,
        url: uri,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );
      return response;
    } catch (e, stack) {
      stopwatch.stop();
      HttpLogger.logError(
        method: method,
        url: uri,
        error: e,
        stackTrace: stack,
        duration: stopwatch.elapsed,
      );
      rethrow;
    }
  }

  static Future<String?> tryRefreshToken() async {
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final deviceId = await DeviceIdHelper.getOrCreateDeviceId();
    final uri = Uri.parse('${AppConstants.baseUrl}/${AppConstants.refreshToken}');
    final headers = {'Content-Type': 'application/json'};
    final body = {
      'refreshToken': refreshToken,
      'deviceId': deviceId,
    };

    final response = await executeWithLogging(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
      requestFn: () => http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await _clearAuthTokens();
      return null;
    }

    final data = jsonDecode(response.body);
    final nextAccessToken = data['accessToken']?.toString();
    final nextRefreshToken = data['refreshToken']?.toString();

    if (nextAccessToken == null || nextAccessToken.isEmpty) {
      await _clearAuthTokens();
      return null;
    }

    await _persistAuthSession(
      accessToken: nextAccessToken,
      refreshToken: nextRefreshToken,
      payload: data,
    );

    return nextAccessToken;
  }

  static Future<void> _persistAuthSession({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? payload,
  }) async {
    await _secureStorage.write(key: 'accessToken', value: accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: 'refreshToken', value: refreshToken);
    }

    if (payload == null) {
      return;
    }

    final pendingTermsConsent = _resolvePendingTermsConsent(payload);
    await _secureStorage.write(
      key: 'pendingTermsConsent',
      value: pendingTermsConsent.toString(),
    );

    final userData = payload['data'];
    if (userData is! Map<String, dynamic>) {
      return;
    }

    await _secureStorage.write(
      key: 'avatarUrl',
      value: userData['avatar']?.toString() ?? '',
    );
    await _secureStorage.write(
      key: 'userName',
      value: userData['name']?.toString() ?? '',
    );
    await _secureStorage.write(
      key: 'userId',
      value: userData['_id']?.toString() ?? '',
    );
  }

  static bool _resolvePendingTermsConsent(Map<String, dynamic> data) {
    final candidates = [
      data['pendingTermsConsent'],
      data['requiresTermsConsent'],
      data['mustAcceptTerms'],
      data['isNewUser'],
      data['newUser'],
      data['isFirstLogin'],
      data['firstLogin'],
      data['data'] is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>)['pendingTermsConsent']
          : null,
      data['data'] is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>)['isNewUser']
          : null,
      data['data'] is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>)['firstLogin']
          : null,
    ];

    for (final candidate in candidates) {
      final resolved = _asBool(candidate);
      if (resolved != null) {
        return resolved;
      }
    }

    return false;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  static Future<void> _clearAuthTokens() async {
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'pendingTermsConsent');
    await _secureStorage.delete(key: 'avatarUrl');
    await _secureStorage.delete(key: 'userName');
    await _secureStorage.delete(key: 'userId');
  }

  static Future<void> _handleUnauthorized(BuildContext context) async {
    await _clearAuthTokens();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  static Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function(String? token) sendRequest,
    BuildContext context, {
    String? token,
  }) async {
    // Ngắt gọi API khi mất mạng, không hiển thị Toast vì đã có NetworkStatusBanner toàn cục
    if (!NetworkConnectivityService.instance.isOnline) {
      throw Exception('NO_INTERNET_CONNECTION');
    }

    var response = await sendRequest(token);

    if (response.statusCode != 401 && response.statusCode != 403) {
      return response;
    }

    final refreshedToken = await tryRefreshToken();
    if (refreshedToken == null) {
      if (context.mounted) {
        await _handleUnauthorized(context);
      }
      return response;
    }

    response = await sendRequest(refreshedToken);

    if (response.statusCode == 401 || response.statusCode == 403) {
      if (context.mounted) {
        await _handleUnauthorized(context);
      }
    }

    return response;
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
      final uri = Uri.parse(url);
      final headers = <String, String>{'Content-Type': 'application/json'};
      final response = await _sendWithRefresh((activeToken) {
        final nextHeaders = Map<String, String>.from(headers);
        if (activeToken != null) {
          nextHeaders['Authorization'] = 'Bearer $activeToken';
        }
        return executeWithLogging(
          method: 'GET',
          uri: uri,
          headers: nextHeaders,
          requestFn: () => http.get(uri, headers: nextHeaders),
        );
      }, context, token: token);

      if (!context.mounted) {
        return _handleResponseWithoutContext(response);
      }
      return _handleResponse(response, context);
    } finally {
      if (showLoading && context.mounted) _hideLoadingDialog(context);
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
      final uri = Uri.parse(url);
      final headers = <String, String>{'Content-Type': 'application/json'};
      final response = await _sendWithRefresh((activeToken) {
        final nextHeaders = Map<String, String>.from(headers);
        if (activeToken != null) {
          nextHeaders['Authorization'] = 'Bearer $activeToken';
        }
        return executeWithLogging(
          method: 'POST',
          uri: uri,
          headers: nextHeaders,
          body: body,
          requestFn: () => http.post(
            uri,
            headers: nextHeaders,
            body: jsonEncode(body),
          ),
        );
      }, context, token: token);

      if (!context.mounted) {
        return _handleResponseWithoutContext(response);
      }
      return _handleResponse(response, context);
    } finally {
      if (showLoading && context.mounted) _hideLoadingDialog(context);
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
      final uri = Uri.parse(url);
      final headers = <String, String>{'Content-Type': 'application/json'};
      final response = await _sendWithRefresh((activeToken) {
        final nextHeaders = Map<String, String>.from(headers);
        if (activeToken != null) {
          nextHeaders['Authorization'] = 'Bearer $activeToken';
        }
        return executeWithLogging(
          method: 'PUT',
          uri: uri,
          headers: nextHeaders,
          body: body,
          requestFn: () => http.put(
            uri,
            headers: nextHeaders,
            body: jsonEncode(body),
          ),
        );
      }, context, token: token);

      if (!context.mounted) {
        return _handleResponseWithoutContext(response);
      }
      return _handleResponse(response, context);
    } finally {
      if (showLoading && context.mounted) _hideLoadingDialog(context);
    }
  }

  // Phương thức PATCH dùng chung
  static Future<dynamic> patch(
    String url,
    BuildContext context, {
    String? token,
    Object? body,
    bool showLoading = false,
  }) async {
    if (showLoading) _showLoadingDialog(context);
    try {
      final uri = Uri.parse(url);
      final headers = <String, String>{'Content-Type': 'application/json'};
      final response = await _sendWithRefresh((activeToken) {
        final nextHeaders = Map<String, String>.from(headers);
        if (activeToken != null) {
          nextHeaders['Authorization'] = 'Bearer $activeToken';
        }
        return executeWithLogging(
          method: 'PATCH',
          uri: uri,
          headers: nextHeaders,
          body: body,
          requestFn: () => http.patch(
            uri,
            headers: nextHeaders,
            body: jsonEncode(body),
          ),
        );
      }, context, token: token);

      if (!context.mounted) {
        return _handleResponseWithoutContext(response);
      }
      return _handleResponse(response, context);
    } finally {
      if (showLoading && context.mounted) _hideLoadingDialog(context);
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
      final uri = Uri.parse(url);
      final headers = <String, String>{'Content-Type': 'application/json'};
      final response = await _sendWithRefresh((activeToken) {
        final nextHeaders = Map<String, String>.from(headers);
        if (activeToken != null) {
          nextHeaders['Authorization'] = 'Bearer $activeToken';
        }
        return executeWithLogging(
          method: 'DELETE',
          uri: uri,
          headers: nextHeaders,
          requestFn: () => http.delete(uri, headers: nextHeaders),
        );
      }, context, token: token);

      if (!context.mounted) {
        return _handleResponseWithoutContext(response);
      }
      return _handleResponse(response, context);
    } finally {
      if (showLoading && context.mounted) _hideLoadingDialog(context);
    }
  }
}
