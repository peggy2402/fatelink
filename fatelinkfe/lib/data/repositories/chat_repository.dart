import 'dart:convert';
import 'package:flutter/material.dart';
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
          .setTransports(['websocket'])
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

  void reconnectSocket() => _socket?.connect();

  void dispose() {
    _socket?.dispose();
  }
}