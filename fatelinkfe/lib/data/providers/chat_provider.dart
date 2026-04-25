import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  final Map<String, bool> _typingStatuses = {};

  final Map<String, bool> _onlineStatuses = {};

  bool isUserTyping(String userId) {
    return _typingStatuses[userId] ?? false;
  }

  bool isUserOnline(String userId) {
    return _onlineStatuses[userId] ?? false;
  }

  void setTypingStatus(String userId, bool isTyping) {
    if (_typingStatuses[userId] != isTyping) {
      _typingStatuses[userId] = isTyping;
      notifyListeners(); // Thông báo cho UI build lại
    }
  }

  void setOnlineStatus(String userId, bool isOnline) {
    if (_onlineStatuses[userId] != isOnline) {
      _onlineStatuses[userId] = isOnline;
      notifyListeners();
    }
  }

  // Cập nhật trạng thái online của nhiều user cùng lúc (dùng cho MatchesScreen)
  void setBulkOnlineStatus(Map<String, dynamic> statuses) {
    statuses.forEach((key, value) => _onlineStatuses[key] = value as bool);
    notifyListeners();
  }
}
