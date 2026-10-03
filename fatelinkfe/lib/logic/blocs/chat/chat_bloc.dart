import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/data/models/chat_message.dart';
import 'package:fatelinkfe/data/repositories/chat_repository.dart';
import '../../../core/utils/secure_storage_helper.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final FlutterSecureStorage secureStorage = SecureStorageHelper.storage;
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
      
      // Chỉ kết nối socket nếu nó chưa được kết nối
      if (!chatRepository.isSocketConnected) {
        chatRepository.connectSocket(token);
      }
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.error, errorMessage: "Lỗi tải lịch sử chat"));
      add(ClearNotificationEvents());
    }
  }

  Future<void> _onSendMessage(ChatSendMessageEvent event, Emitter<ChatState> emit) async {
    final userMessage = ChatMessage(text: event.text, isSentByMe: true, timestamp: DateTime.now());
    emit(state.copyWith(
      messages: List.from(state.messages)..add(userMessage),
      showEmotionSuggestions: false,
      isTyping: true,
    ));

    // 1. Thử gửi qua WebSocket nếu đang kết nối
    if (chatRepository.isSocketConnected) {
      chatRepository.sendMessage(event.text);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 12), () async {
        if (state.isTyping) {
          final token = await secureStorage.read(key: 'accessToken');
          if (token != null) {
            final reply = await chatRepository.sendAiMessageViaRest(event.text, token);
            if (reply != null && reply.isNotEmpty) {
              add(ChatMessageReceived(ChatMessage(
                text: reply,
                isSentByMe: false,
                timestamp: DateTime.now(),
              )));
              return;
            }
          }
          add(ChatTypingTimeout());
        }
      });
      return;
    }

    // 2. Nếu Socket chưa kết nối, chuyển ngay sang HTTP REST Fallback
    chatRepository.reconnectSocket();
    final token = await secureStorage.read(key: 'accessToken');
    if (token != null) {
      final reply = await chatRepository.sendAiMessageViaRest(event.text, token);
      if (reply != null && reply.isNotEmpty) {
        emit(state.copyWith(
          messages: List.from(state.messages)..add(ChatMessage(
            text: reply,
            isSentByMe: false,
            timestamp: DateTime.now(),
          )),
          isTyping: false,
        ));
        return;
      }
    }

    // 3. Nếu cả hai phương thức đều không thành công
    emit(state.copyWith(
      isTyping: false,
      errorMessage: "Mạng yếu hoặc Faye đang bận. Vui lòng thử lại sau!",
    ));
    add(ClearNotificationEvents());
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