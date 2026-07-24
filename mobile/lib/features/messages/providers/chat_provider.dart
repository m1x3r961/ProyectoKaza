import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_config.dart';

class KazaMessageItem {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isMe;

  KazaMessageItem({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    required this.isMe,
  });
}

class ChatState {
  final List<KazaMessageItem> messages;
  final bool isLoading;
  final String? visitStatus; // 'REQUESTED', 'CONFIRMED', 'CHECKED_IN'
  final DateTime? visitScheduledAt;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.visitStatus = 'CONFIRMED',
    this.visitScheduledAt,
  });

  ChatState copyWith({
    List<KazaMessageItem>? messages,
    bool? isLoading,
    String? visitStatus,
    DateTime? visitScheduledAt,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      visitStatus: visitStatus ?? this.visitStatus,
      visitScheduledAt: visitScheduledAt ?? this.visitScheduledAt,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState()) {
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    final now = DateTime.now();
    state = state.copyWith(
      messages: [
        KazaMessageItem(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'usr-agent',
          senderName: 'Carlos Mendoza (Inmobiliaria Kaza Pro)',
          content: '¡Hola! Gracias por consultar por el Departamento en Equipetrol. ¿Aceptas visita mañana?',
          createdAt: now.subtract(const Duration(minutes: 45)),
          isMe: false,
        ),
        KazaMessageItem(
          id: 'msg-2',
          conversationId: 'conv-1',
          senderId: 'usr-me',
          senderName: 'Tú',
          content: '¡Hola Carlos! Sí, me gustaría agendar la visita a las 15:00 PM y verificar si aceptan crédito bancario.',
          createdAt: now.subtract(const Duration(minutes: 30)),
          isMe: true,
        ),
        KazaMessageItem(
          id: 'msg-3',
          conversationId: 'conv-1',
          senderId: 'usr-agent',
          senderName: 'Carlos Mendoza (Inmobiliaria Kaza Pro)',
          content: 'Excelente, sí aceptamos financiamiento. Cita de visita confirmada para mañana a las 15:00 PM con protocolo Visit Safety.',
          createdAt: now.subtract(const Duration(minutes: 10)),
          isMe: false,
        ),
      ],
      visitScheduledAt: now.add(const Duration(days: 1)),
    );

    _listenRealtimeChannel();
  }

  void _listenRealtimeChannel() {
    try {
      if (SupabaseConfig.supabaseAnonKey != 'TU_SUPABASE_ANON_KEY_AQUI') {
        SupabaseConfig.client
            .channel('public:messages')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              callback: (payload) {
                final newRow = payload.newRecord;
                final newMessage = KazaMessageItem(
                  id: newRow['id'] ?? DateTime.now().toIso8601String(),
                  conversationId: newRow['conversation_id'] ?? 'conv-1',
                  senderId: newRow['sender_user_id'] ?? 'usr-agent',
                  senderName: 'Carlos Mendoza',
                  content: newRow['content'] ?? '',
                  createdAt: DateTime.now(),
                  isMe: false,
                );
                state = state.copyWith(messages: [...state.messages, newMessage]);
              },
            )
            .subscribe();
      }
    } catch (e) {
      // Realtime fallback mode
    }
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final myMsg = KazaMessageItem(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: 'conv-1',
      senderId: 'usr-me',
      senderName: 'Tú',
      content: text.trim(),
      createdAt: DateTime.now(),
      isMe: true,
    );

    state = state.copyWith(messages: [...state.messages, myMsg]);

    try {
      if (SupabaseConfig.supabaseAnonKey != 'TU_SUPABASE_ANON_KEY_AQUI') {
        SupabaseConfig.client.rpc('fn_send_kaza_message', params: {
          'p_conversation_id': '11111111-1111-1111-1111-111111111111',
          'p_sender_id': '22222222-2222-2222-2222-222222222222',
          'p_content': text.trim(),
        });
      }
    } catch (e) {
      // Fallback
    }
  }

  void performVisitCheckIn() {
    state = state.copyWith(visitStatus: 'CHECKED_IN');
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
