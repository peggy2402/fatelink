import 'package:fatelinkfe/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../models/match_user.dart';

class HomeRepository {
  final FlutterSecureStorage secureStorage;

  // Khuyến khích truyền vào qua Constructor để dễ dàng Unit Test
  HomeRepository({this.secureStorage = const FlutterSecureStorage()});

  Future<List<MatchUser>> fetchRecommendations({
    required BuildContext context,
  }) async {
    final token = await secureStorage.read(key: 'accessToken');
    if (token == null) throw Exception('Token is null');

    // Gọi đúng endpoint lấy danh sách người dùng được AI phân tích
    final url = '${AppConstants.baseUrl}/matchmaking/recommendations';

    final response = await ApiService.get(url, context, token: token);

    if (response != null && response is List) {
      return response.map((json) => MatchUser.fromJson(json)).toList();
    }

    return [];
  }
}
