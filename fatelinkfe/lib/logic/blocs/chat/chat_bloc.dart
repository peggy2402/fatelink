import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fatelinkfe/data/models/chat_message.dart';
import 'package:fatelinkfe/data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  Timer? _typingTimer;

  ChatBloc({required this.chatRepository}) : super(const ChatState()) {
    on<ChatInitializeEvent>(_onInitialize);
    on<ChatSendMessageEvent>(_onSendMessage);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMatchReadyReceived>(_onMatchReadyReceived);
    on<ChatErrorReceived>(_onErrorReceived);
    on<ChatTypingTimeout>(_onTypingTimeout);
    on<ClearNotificationEvents>(_onClearNotificationEvents);

    // Liên kết stream từ Repository sang Event của BLoC
    chatRepository.onMessageReceived = (msg) => add(ChatMessageReceived(msg));
    chatRepository.onMatchReady = (msg) => add(ChatMatchReadyReceived(msg));
    chatRepository.onError = (err) => add(ChatErrorReceived(err));
  }

  Future<void> _onInitialize(ChatInitializeEvent event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final token = await secureStorage.read(key: 'accessToken');
      if (token == null) {
        emit(state.copyWith(status: ChatStatus.loaded));
        return;
      }
      
      final history = await chatRepository.getChatHistory(token, event.context);
      bool showSuggestions = false;
      final messages = List<ChatMessage>.from(history);
      
      if (messages.isEmpty) {
        messages.add(ChatMessage(
          text: "Hôm nay tâm trạng của bạn đang như thế nào? 🍂",
          isSentByMe: false,
          timestamp: DateTime.now(),
        ));
        showSuggestions = true;
      }
      
      emit(state.copyWith(status: ChatStatus.loaded, messages: messages, showEmotionSuggestions: showSuggestions));
      chatRepository.connectSocket(token);
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.error, errorMessage: "Lỗi tải lịch sử chat"));
      add(ClearNotificationEvents());
    }
  }

  void _onSendMessage(ChatSendMessageEvent event, Emitter<ChatState> emit) {
    if (!chatRepository.isSocketConnected) {
      emit(state.copyWith(errorMessage: "Mất kết nối máy chủ. Đang thử kết nối lại..."));
      add(ClearNotificationEvents());
      chatRepository.reconnectSocket();
      return;
    }

    final userMessage = ChatMessage(text: event.text, isSentByMe: true, timestamp: DateTime.now());
    emit(state.copyWith(messages: List.from(state.messages)..add(userMessage), showEmotionSuggestions: false, isTyping: true));

    chatRepository.sendMessage(event.text);
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 15), () => add(ChatTypingTimeout()));
  }

  void _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    _typingTimer?.cancel();
    emit(state.copyWith(messages: List.from(state.messages)..add(event.message), isTyping: false));
  }

  void _onMatchReadyReceived(ChatMatchReadyReceived event, Emitter<ChatState> emit) {
    emit(state.copyWith(matchReadyMessage: event.message));
    add(ClearNotificationEvents());
  }

  void _onErrorReceived(ChatErrorReceived event, Emitter<ChatState> emit) {
    _typingTimer?.cancel();
    emit(state.copyWith(isTyping: false, errorMessage: event.error));
    add(ClearNotificationEvents());
  }

  void _onTypingTimeout(ChatTypingTimeout event, Emitter<ChatState> emit) {
    if (state.isTyping) emit(state.copyWith(isTyping: false, errorMessage: "Mạng yếu hoặc Faye đang bận. Vui lòng thử lại!"));
    add(ClearNotificationEvents());
  }
  void _onClearNotificationEvents(ClearNotificationEvents event, Emitter<ChatState> emit) => emit(state.copyWith(errorMessage: '', matchReadyMessage: ''));
  @override Future<void> close() { _typingTimer?.cancel(); chatRepository.dispose(); return super.close(); }
}