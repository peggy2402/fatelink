import 'package:equatable/equatable.dart';
import '../../../repositories/chat_repository.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class ConnectChatEvent extends ChatEvent {}

class DisconnectChatEvent extends ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String text;
  const SendMessageEvent(this.text);
  @override
  List<Object> get props => [text];
}

// Sự kiện nội bộ được kích hoạt khi nhận Stream từ Repository
class MessageReceivedEvent extends ChatEvent {
  final ChatMessage message;
  const MessageReceivedEvent(this.message);
}

class TypingStatusChangedEvent extends ChatEvent {
  final bool isTyping;
  const TypingStatusChangedEvent(this.isTyping);
}

class MatchReadyEvent extends ChatEvent {}
