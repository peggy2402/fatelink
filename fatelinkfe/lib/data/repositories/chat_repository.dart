import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fatelinkfe/services/api_service.dart';
import 'package:fatelinkfe/core/utils/constants.dart';
import 'package:fatelinkfe/data/models/chat_message.dart';

class ChatRepository {
  IO.Socket? _socket;
  
  // Các callback để stream data về BLoC
  Function(ChatMessage)? onMessageReceived;
  Function(String)? onMatchReady;
  Function(String)? onError;

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload);
      return data['sub'] ?? data['id'] ?? data['userId'];
    } catch (e) {
      return null;
    }
  }

  Future<List<ChatMessage>> getChatHistory(String token, BuildContext context) async {
    final userId = _getUserIdFromToken(token);
    if (userId == null) throw Exception('Token không hợp lệ');

    final url = '${AppConstants.baseUrl}/messages/$userId?limit=50';
    final data = await ApiService.get(url, context, token: token);
    
    if (data != null) {
      final List<dynamic> historyData = data;
      return historyData.map((msg) => ChatMessage(
        text: msg['text'],
        isSentByMe: msg['isSentByMe'],
        timestamp: DateTime.parse(msg['timestamp']).toLocal(),
      )).toList();
    }
    return [];
  }

  void connectSocket(String token) {
    _socket = IO.io(
      AppConstants.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();
    _socket!.onConnect((_) => debugPrint('✅ Socket connected'));
    _socket!.onDisconnect((_) => debugPrint('❌ Socket disconnected'));

    _socket!.on('receiveMessage', (data) {
      onMessageReceived?.call(ChatMessage(
        text: data['text'],
        isSentByMe: false,
        timestamp: DateTime.parse(data['timestamp']).toLocal(),
      ));
    });

    _socket!.on('errorMessage', (data) => onError?.call(data['message']));
    _socket!.on('matchReady', (data) => onMatchReady?.call(data['message'] ?? 'Faye đã hiểu rõ bạn.'));
  }

  bool get isSocketConnected => _socket?.connected ?? false;

  void sendMessage(String text) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendMessage', {'text': text});
    }
  }

  /// Phương thức gửi tin nhắn AI trực tiếp qua HTTP REST (Fallback khi Socket bị ngắt hoặc chậm)
  Future<String?> sendAiMessageViaRest(String text, String token) async {
    final url = Uri.parse('${AppConstants.baseUrl}/chat/message');
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': text}),
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['reply'] != null) {
          final raw = data['reply'].toString();
          try {
            final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
            final parsed = jsonDecode(clean);
            if (parsed is Map && parsed['reply'] != null) {
              return parsed['reply'].toString();
            }
          } catch (_) {}
          return raw;
        }
      }
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn AI qua REST fallback: $e');
    }
    return null;
  }

  void reconnectSocket() => _socket?.connect();

  void dispose() {
    _socket?.dispose();
  }
}