import 'package:equatable/equatable.dart';
import '../../../repositories/chat_repository.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatConnecting extends ChatState {}

class ChatConnected extends ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? matchReadyMessage;

  const ChatConnected({
    required this.messages,
    this.isTyping = false,
    this.matchReadyMessage,
  });

  ChatConnected copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? matchReadyMessage,
  }) {
    return ChatConnected(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      matchReadyMessage: matchReadyMessage, // Bỏ null nếu không truyền
    );
  }

  @override
  List<Object?> get props => [messages, isTyping, matchReadyMessage];
}

class ChatError extends ChatState {
  final String error;
  const ChatError(this.error);

  @override
  List<Object?> get props => [error];
}
