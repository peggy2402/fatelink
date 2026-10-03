import 'dart:convert';
import 'package:flutter/foundation.dart';

/// CosmicHttpLogger: Tiện ích ghi log HTTP toàn diện ra Debug Console cho tất cả các API
/// Hiển thị rõ ràng URL API, HTTP Method, Request Headers, Request Body, Response Status, Response Body và thời gian phản hồi.
class HttpLogger {
  static const bool _enabled = true;

  /// Log thông tin Request được gửi đi
  static void logRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
  }) {
    if (!_enabled || !kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('\n┌──────────────────────── [HTTP REQUEST] ────────────────────────');
    buffer.writeln('│ 🌐 [API]  : ${method.toUpperCase()} $url');
    if (headers != null && headers.isNotEmpty) {
      final sanitizedHeaders = Map<String, String>.from(headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        final authVal = sanitizedHeaders['Authorization']!;
        if (authVal.length > 25) {
          sanitizedHeaders['Authorization'] =
              '${authVal.substring(0, 15)}...${authVal.substring(authVal.length - 6)}';
        }
      }
      buffer.writeln('│ 📋 [HEAD] : $sanitizedHeaders');
    }
    if (body != null) {
      buffer.writeln('│ 📦 [BODY] :');
      buffer.writeln(_prettyFormat(body));
    } else {
      buffer.writeln('│ 📦 [BODY] : (Empty)');
    }
    buffer.writeln('└───────────────────────────────────────────────────────────────');
    _print(buffer.toString());
  }

  /// Log thông tin Response nhận về từ Server
  static void logResponse({
    required String method,
    required Uri url,
    required int statusCode,
    required String? body,
    Duration? duration,
  }) {
    if (!_enabled || !kDebugMode) return;

    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅ SUCCESS' : '❌ ERROR';
    final buffer = StringBuffer();
    buffer.writeln('\n┌────────────────── [HTTP RESPONSE: $icon] ──────────────────');
    buffer.writeln('│ 🌐 [API]  : ${method.toUpperCase()} $url');
    buffer.writeln(
      '│ 📊 [CODE] : $statusCode ${duration != null ? "⏱️ (${duration.inMilliseconds}ms)" : ""}',
    );
    if (body != null && body.trim().isNotEmpty) {
      buffer.writeln('│ 📥 [BODY] :');
      buffer.writeln(_prettyFormat(body));
    } else {
      buffer.writeln('│ 📥 [BODY] : (Empty)');
    }
    buffer.writeln('└───────────────────────────────────────────────────────────────');
    _print(buffer.toString());
  }

  /// Log lỗi khi gửi request thất bại (Timeout, SocketException, Không có mạng...)
  static void logError({
    required String method,
    required Uri url,
    required Object error,
    StackTrace? stackTrace,
    Duration? duration,
  }) {
    if (!_enabled || !kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('\n┌────────────────── [HTTP REQUEST EXCEPTION 💥] ──────────────────');
    buffer.writeln('│ 🌐 [API]  : ${method.toUpperCase()} $url');
    if (duration != null) {
      buffer.writeln('│ ⏱️ [TIME] : ${duration.inMilliseconds}ms');
    }
    buffer.writeln('│ 💥 [ERR]  : $error');
    if (stackTrace != null) {
      final lines = stackTrace.toString().split('\n').take(3).join('\n│   ');
      buffer.writeln('│ 📍 [TRACE]:\n│   $lines');
    }
    buffer.writeln('└───────────────────────────────────────────────────────────────');
    _print(buffer.toString());
  }

  /// Định dạng JSON đẹp mắt hoặc xuống dòng
  static String _prettyFormat(Object data) {
    try {
      dynamic parsed;
      if (data is String) {
        final trimmed = data.trim();
        if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
          parsed = jsonDecode(trimmed);
        } else {
          return trimmed.split('\n').map((l) => '│   $l').join('\n');
        }
      } else {
        parsed = data;
      }
      const encoder = JsonEncoder.withIndent('  ');
      final pretty = encoder.convert(parsed);
      return pretty.split('\n').map((line) => '│   $line').join('\n');
    } catch (_) {
      return data.toString().split('\n').map((line) => '│   $line').join('\n');
    }
  }

  static void _print(String text) {
    debugPrint(text);
  }
}
