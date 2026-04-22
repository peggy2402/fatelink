import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../screens/chat_screen.dart'; // Nơi chứa model ChatMessage (nếu có)

// Tạm định nghĩa model tin nhắn (bạn có thể dùng model hiện tại của bạn)
class ChatMessage {
  final String text;
  final bool isSentByMe;
  final String timestamp;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
  });
}

class ChatRepository {
  IO.Socket? _socket;
  final _secureStorage = const FlutterSecureStorage();

  // Dùng StreamController để truyền dữ liệu từ Socket lên BLoC
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<bool>.broadcast();
  final _matchReadyController = StreamController<String>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<bool> get typingStream => _typingController.stream;
  Stream<String> get matchReadyStream => _matchReadyController.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _secureStorage.read(key: 'accessToken');
    if (token == null) throw Exception('Vui lòng đăng nhập lại');

    _socket = IO.io(
      AppConstants.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Đã kết nối Socket.IO');
    });

    // Lắng nghe tin nhắn mới từ AI / Người thật
    _socket!.on('receiveMessage', (data) {
      final message = ChatMessage(
        text: data['text'],
        isSentByMe: data['isSentByMe'] ?? false,
        timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
      );
      _messageController.add(message);
    });

    // Lắng nghe sự kiện Faye báo "Đã hiểu người dùng"
    _socket!.on('matchReady', (data) {
      _matchReadyController.add(data['message'] ?? 'Faye đã hiểu bạn!');
    });

    // Lắng nghe trạng thái gõ phím
    _socket!.on('receiveTyping', (data) {
      _typingController.add(data['isTyping'] ?? false);
    });
  }

  void sendMessage(String text) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendMessage', {'text': text});
    }
  }

  void emitTyping(bool isTyping, {String? partnerId}) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {'partnerId': partnerId, 'isTyping': isTyping});
    }
  }

  void disconnect() {
    _socket?.disconnect();
  }
}
