import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message_usecase.dart';

class MayaState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? sessionId;

  MayaState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.sessionId,
  });

  MayaState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? sessionId,
  }) {
    return MayaState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class MayaController extends StateNotifier<MayaState> {
  final SendMessageUseCase _sendMessageUseCase;

  MayaController(this._sendMessageUseCase) : super(MayaState()) {
    // Mensaje de bienvenida inicial
    _addInitialMessage();
  }

  void _addInitialMessage() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          id: 'initial',
          content: '¡Hola! Soy Maya, tu asistente apícola. ¿En qué puedo ayudarte hoy?',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> sendMessage(String content, {Map<String, dynamic>? context}) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    final result = await _sendMessageUseCase.execute(
      prompt: content,
      sessionId: state.sessionId,
      context: context,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (assistantMessage) {
        state = state.copyWith(
          messages: [...state.messages, assistantMessage],
          isLoading: false,
          // Nota: El sessionId debería venir en la respuesta si el backend lo maneja así
          // Por ahora asumimos que el repository lo podría extraer o persistir
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
