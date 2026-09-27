import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(conversationsProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Conversaciones')),
        body: rows.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
                child: TextButton(
                    onPressed: () => ref.invalidate(conversationsProvider),
                    child: const Text('Reintentar carga de conversaciones'))),
            data: (items) => items.isEmpty
                ? const Center(
                    child: Text(
                        'Contactá un anunciante desde una propiedad para iniciar una conversación.'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final c = items[i];
                      final title =
                          (c['listings'] as Map?)?['title'] as String? ??
                              'Consulta inmobiliaria';
                      return ListTile(
                          title: Text(title),
                          leading: const Icon(Icons.chat_outlined),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                      title: title,
                                      conversationId: c['id'] as String))));
                    })));
  }
}
