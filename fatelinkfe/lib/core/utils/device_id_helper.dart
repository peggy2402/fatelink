import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdHelper {
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'deviceId';

  static Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _generateDeviceId();
    await _storage.write(key: _deviceIdKey, value: created);
    return created;
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final suffix = List.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'flutter-$timestamp-$suffix';
  }
}
