import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized SecureStorage helper with automatic fallback and error recovery.
/// Configured with `resetOnError: true` to prevent `BadPaddingException: BAD_DECRYPT`
/// when Android KeyStore keys change after app reinstallation or restore.
class SecureStorageHelper {
  static const AndroidOptions defaultAndroidOptions = AndroidOptions(
    resetOnError: true,
  );

  static const IOSOptions defaultIOSOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  static const FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: defaultAndroidOptions,
    iOptions: defaultIOSOptions,
  );

  /// Safe read: catches any decrypt or platform error, clears key if corrupted, returns null
  static Future<String?> read(String key) async {
    try {
      return await storage.read(key: key);
    } catch (e) {
      debugPrint('SecureStorageHelper.read error for key "$key": $e');
      try {
        await storage.delete(key: key);
      } catch (_) {}
      return null;
    }
  }

  /// Safe write: catches error and attempts clean rewrite if needed
  static Future<void> write(String key, String value) async {
    try {
      await storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorageHelper.write error for key "$key": $e');
      try {
        await storage.delete(key: key);
        await storage.write(key: key, value: value);
      } catch (retryError) {
        debugPrint('SecureStorageHelper.write retry failed: $retryError');
      }
    }
  }

  /// Safe delete
  static Future<void> delete(String key) async {
    try {
      await storage.delete(key: key);
    } catch (e) {
      debugPrint('SecureStorageHelper.delete error for key "$key": $e');
    }
  }

  /// Safe deleteAll
  static Future<void> deleteAll() async {
    try {
      await storage.deleteAll();
    } catch (e) {
      debugPrint('SecureStorageHelper.deleteAll error: $e');
    }
  }
}
