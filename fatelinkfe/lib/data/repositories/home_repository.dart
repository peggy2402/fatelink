import 'package:fatelinkfe/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../models/match_user.dart';

class HomeRepository {
  final FlutterSecureStorage secureStorage;

  // Khuyến khích truyền vào qua Constructor để dễ dàng Unit Test
  HomeRepository({this.secureStorage = SecureStorageHelper.storage});

  Future<List<MatchUser>> fetchRecommendations({
    required BuildContext context,
  }) async {
    final token = await secureStorage.read(key: 'accessToken');
    if (token == null) throw Exception('Token is null');

    // Gọi đúng endpoint lấy danh sách người dùng được AI phân tích
    final url = '${AppConstants.baseUrl}/${AppConstants.matchmakingRecommendations}';
    if (!context.mounted) return [];
    final response = await ApiService.get(url, context, token: token);

    if (response != null && response is List) {
      return response
          .map((json) => MatchUser.fromJson(json))
          .where((user) => !user.id.startsWith('sim-'))
          .toList();
    }

    return [];
  }

  Future<bool> updateUserFrequency({
    required BuildContext context,
    required String mood,
    required String vibe,
    required String signal,
    String? frequencyHertz,
  }) async {
    final token = await secureStorage.read(key: 'accessToken');
    if (token == null) return false;

    final url = '${AppConstants.baseUrl}/users/frequency';
    final body = {
      'mood': mood,
      'vibe': vibe,
      'signal': signal,
      ...?frequencyHertz == null ? null : {'frequencyHertz': frequencyHertz},
    };

    try {
      if (!context.mounted) return false;
      final response = await ApiService.post(url, context, body: body, token: token);
      return response != null;
    } catch (_) {
      return false;
    }
  }
}
