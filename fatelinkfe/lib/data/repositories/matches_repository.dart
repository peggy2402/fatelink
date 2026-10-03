import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/constants.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../../services/api_service.dart';
import '../../presentation/screens/match/matches_screen.dart'; // Nơi chứa model MatchedUser

class MatchesRepository {
  final _secureStorage = SecureStorageHelper.storage;

  Future<List<MatchedUser>> fetchMatches({required int page}) async {
    final token = await _secureStorage.read(key: 'accessToken');
    if (token == null) throw Exception('Token is null');

    final parts = token.split('.');
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final userId = jsonDecode(payload)['sub'] ?? jsonDecode(payload)['id'];

    final url = Uri.parse('${AppConstants.baseUrl}/${AppConstants.userMatches(userId)}?page=$page&limit=10');
    final headers = {'Authorization': 'Bearer $token'};
    final response = await ApiService.executeWithLogging(
      method: 'GET',
      uri: url,
      headers: headers,
      requestFn: () => http.get(url, headers: headers),
    );

    if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((json) => MatchedUser.fromJson(json)).toList();
      }
    }
    return [];
  }
  
  // TODO: Bổ sung thêm hàm unmatchUser() ở đây khi cần
}