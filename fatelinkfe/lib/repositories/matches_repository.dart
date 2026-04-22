import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../screens/matches_screen.dart'; // Nơi chứa model MatchedUser

class MatchesRepository {
  final _secureStorage = const FlutterSecureStorage();

  Future<List<MatchedUser>> fetchMatches({required int page}) async {
    final token = await _secureStorage.read(key: 'accessToken');
    if (token == null) throw Exception('Token is null');

    final parts = token.split('.');
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final userId = jsonDecode(payload)['sub'] ?? jsonDecode(payload)['id'];

    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.userMatches(userId)}?page=$page&limit=10');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

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