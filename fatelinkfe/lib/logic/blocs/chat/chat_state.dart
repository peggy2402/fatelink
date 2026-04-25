import 'package:fatelinkfe/data/models/chat_message.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatState {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool showEmotionSuggestions;
  final String errorMessage;
  final String matchReadyMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.isTyping = false,
    this.showEmotionSuggestions = false,
    this.errorMessage = '',
    this.matchReadyMessage = '',
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? showEmotionSuggestions,
    String? errorMessage,
    String? matchReadyMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      showEmotionSuggestions: showEmotionSuggestions ?? this.showEmotionSuggestions,
      errorMessage: errorMessage ?? this.errorMessage,
      matchReadyMessage: matchReadyMessage ?? this.matchReadyMessage,
    );
  }
}