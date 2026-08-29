import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';

/// Estado del chat con Imagina
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier que gestiona el historial del chat y llama al servicio de Gemini
class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiService _service;

  AiChatNotifier(this._service)
      : super(
          const AiChatState(
            messages: [
              ChatMessage(
                text:
                    '¡Hola! Soy Imagina, tu asistente de KAZA 🏠\n\n'
                    'Puedo ayudarte a entender el mercado inmobiliario boliviano, '
                    'analizar propiedades, comparar precios y más.\n\n'
                    '¿En qué puedo ayudarte hoy?',
                isUser: false,
              ),
            ],
          ),
        );

  /// Envía un mensaje del usuario y espera la respuesta de Gemini
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Agregar mensaje del usuario
    final userMsg = ChatMessage(text: text.trim(), isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _service.sendMessage(
        userMessage: text.trim(),
        history: state.messages,
      );

      final aiMsg = ChatMessage(text: response, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      final errorText = e.toString().contains('Exception:')
          ? e.toString().split('Exception:').last.trim()
          : 'Lo siento, tuve un problema al conectarme. Intenta de nuevo en un momento.';

      final errorMsg = ChatMessage(
        text: '⚠️ $errorText',
        isUser: false,
        isError: true,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        error: errorText,
      );
    }
  }

  /// Limpia el historial y reinicia el chat
  void clearChat() {
    state = const AiChatState(
      messages: [
        ChatMessage(
          text:
              '¡Hola! Soy Imagina, tu asistente de KAZA 🏠\n\n'
              '¿En qué puedo ayudarte hoy?',
          isUser: false,
        ),
      ],
    );
  }
}

/// Provider global del chat Imagina
final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(AiService());
});
