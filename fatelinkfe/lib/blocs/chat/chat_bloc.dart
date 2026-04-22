import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import './chat_state.dart';
import '../../../repositories/chat_repository.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _matchReadySubscription;

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    on<ConnectChatEvent>(_onConnect);
    on<SendMessageEvent>(_onSendMessage);
    on<DisconnectChatEvent>(_onDisconnect);

    // Xử lý các sự kiện được đẩy từ Stream của Repository
    on<MessageReceivedEvent>(_onMessageReceived);
    on<TypingStatusChangedEvent>(_onTypingStatusChanged);
    on<MatchReadyEvent>((event, emit) {
      if (state is ChatConnected) {
        emit(
          (state as ChatConnected).copyWith(
            matchReadyMessage: "Đã thấu hiểu tâm hồn",
          ),
        );
      }
    });
  }

  Future<void> _onConnect(
    ConnectChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatConnecting());
    try {
      await chatRepository.connect();

      // Bắt đầu lắng nghe Stream từ Socket
      _messageSubscription = chatRepository.messageStream.listen((message) {
        add(MessageReceivedEvent(message));
      });
      _typingSubscription = chatRepository.typingStream.listen((isTyping) {
        add(TypingStatusChangedEvent(isTyping));
      });
      _matchReadySubscription = chatRepository.matchReadyStream.listen((msg) {
        add(MatchReadyEvent());
      });

      // TODO: Gọi API load lịch sử chat cũ (http.get) ở đây rồi đưa vào messages
      emit(const ChatConnected(messages: []));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) {
    chatRepository.sendMessage(event.text);

    // Cập nhật giao diện ngay lập tức (Optimistic UI)
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      final newMessage = ChatMessage(
        text: event.text,
        isSentByMe: true,
        timestamp: DateTime.now().toIso8601String(),
      );
      emit(
        currentState.copyWith(messages: [...currentState.messages, newMessage]),
      );
    }
  }

  void _onMessageReceived(MessageReceivedEvent event, Emitter<ChatState> emit) {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      // Nhận tin nhắn mới từ Faye, tắt trạng thái typing
      emit(
        currentState.copyWith(
          messages: [...currentState.messages, event.message],
          isTyping: false,
        ),
      );
    }
  }

  void _onTypingStatusChanged(
    TypingStatusChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatConnected) {
      emit((state as ChatConnected).copyWith(isTyping: event.isTyping));
    }
  }

  void _onDisconnect(DisconnectChatEvent event, Emitter<ChatState> emit) {
    chatRepository.disconnect();
    emit(ChatInitial());
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _matchReadySubscription?.cancel();
    chatRepository.disconnect();
    return super.close();
  }
}
