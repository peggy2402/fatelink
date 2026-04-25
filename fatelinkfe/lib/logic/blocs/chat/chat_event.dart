import 'package:flutter/material.dart';
import 'package:fatelinkfe/data/models/chat_message.dart';

abstract class ChatEvent {}

class ChatInitializeEvent extends ChatEvent {
  final BuildContext context;
  ChatInitializeEvent(this.context);
}

class ChatSendMessageEvent extends ChatEvent {
  final String text;
  ChatSendMessageEvent(this.text);
}

class ChatMessageReceived extends ChatEvent {
  final ChatMessage message;
  ChatMessageReceived(this.message);
}

class ChatMatchReadyReceived extends ChatEvent {
  final String message;
  ChatMatchReadyReceived(this.message);
}

class ChatErrorReceived extends ChatEvent {
  final String error;
  ChatErrorReceived(this.error);
}
class ChatTypingTimeout extends ChatEvent {}
class ClearNotificationEvents extends ChatEvent {}