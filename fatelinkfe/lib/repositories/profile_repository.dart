import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fatelinkfe/services/api_service.dart';
import '../utils/constants.dart';

class ProfileRepository {
  final _secureStorage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> fetchUserProfile(BuildContext context) async {
    final token = await _secureStorage.read(key: 'accessToken');
    if (token == null) throw Exception('Token is null');

    // Parse payload để lấy userID
    final parts = token.split('.');
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final userId = jsonDecode(payload)['sub'] ?? jsonDecode(payload)['id'];

    final url = '${AppConstants.baseUrl}${AppConstants.userProfile(userId)}';

    final response = await ApiService.get(url, context, token: token);
    return response is Map<String, dynamic> ? response : {};
  }
}
