import 'package:fatelinkfe/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HomeRepository {
  final _secureStorage = const FlutterSecureStorage();

  Future<List<dynamic>> fetchRecommendations({
    required int page,
    required BuildContext context,
  }) async {
    final token = await _secureStorage.read(key: 'accessToken');
    if (token == null) throw Exception('Token is null');

    // Đảm bảo bạn đã thêm biến endpoint /users/recommendations vào backend
    final url =
        '${AppConstants.baseUrl}/${AppConstants.userRecommendations}?page=$page&limit=10';

    final response = await ApiService.get(url, context, token: token);

    if (response != null && response is List) {
      return response;
    }

    return [];
  }
}
