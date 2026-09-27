import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

final conversationMessagesProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, id) {
  final auth = ref.watch(kazaAuthProvider);
  if (!auth.isAuthenticated) return Stream.value([]);
  return SupabaseConfig.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', id)
      .order('created_at', ascending: false)
      .limit(100);
});
final conversationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(kazaAuthProvider);
  if (!auth.isAuthenticated) return [];
  return List<Map<String, dynamic>>.from(
      await ApiClient().request('/api/conversations'));
});
Future<void> sendConversationMessage(
    String conversation, String text, String clientId) async {
  await ApiClient().request('/api/conversations/$conversation/messages',
      method: 'POST', body: {'content': text, 'clientId': clientId});
}
