class ChatMessage {
  final String id;
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;
  final String? reaction;
  final String? replyToText;
  final String? replyToSender;
  final bool isRevoked;
  final List<String> imageUrls;
  final String messageType; // 'text', 'imageStack', 'voice', 'location', 'revoked'

  ChatMessage({
    String? id,
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
    this.reaction,
    this.replyToText,
    this.replyToSender,
    this.isRevoked = false,
    this.imageUrls = const [],
    this.messageType = 'text',
  }) : id = id ?? '${timestamp.millisecondsSinceEpoch}_${text.hashCode}';

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isSentByMe,
    DateTime? timestamp,
    String? reaction,
    String? replyToText,
    String? replyToSender,
    bool? isRevoked,
    List<String>? imageUrls,
    String? messageType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      timestamp: timestamp ?? this.timestamp,
      reaction: reaction ?? this.reaction,
      replyToText: replyToText ?? this.replyToText,
      replyToSender: replyToSender ?? this.replyToSender,
      isRevoked: isRevoked ?? this.isRevoked,
      imageUrls: imageUrls ?? this.imageUrls,
      messageType: messageType ?? this.messageType,
    );
  }
}