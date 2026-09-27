import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/supabase_config.dart';
import '../providers/chat_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String title;
  final String? orgName;
  final String conversationId;
  const ChatDetailScreen(
      {super.key,
      required this.title,
      required this.conversationId,
      this.orgName});
  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;
  String? _attemptText;
  String _clientId = ApiClient.newId();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    if (_attemptText != text) _clientId = ApiClient.newId();
    _attemptText = text;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await sendConversationMessage(widget.conversationId, text, _clientId);
      if (mounted) {
        _text.clear();
        _attemptText = null;
        ref.invalidate(conversationMessagesProvider(widget.conversationId));
      }
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'No se confirmó el envío. El texto se conserva para reintentar.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages =
        ref.watch(conversationMessagesProvider(widget.conversationId));
    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(children: [
          Expanded(
              child: messages.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(
                      child: TextButton(
                          onPressed: () => ref.invalidate(
                              conversationMessagesProvider(
                                  widget.conversationId)),
                          child: const Text(
                              'No se pudieron cargar los mensajes. Reintentar'))),
                  data: (rows) => rows.isEmpty
                      ? const Center(child: Text('Todavía no hay mensajes.'))
                      : ListView.builder(
                          reverse: true,
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final m = rows[i];
                            final mine = m['sender_user_id'] ==
                                SupabaseConfig.client.auth.currentUser?.id;
                            return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Card(
                                    child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(m['content'] as String))));
                          }))),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child:
                    Text(_error!, style: const TextStyle(color: Colors.red))),
          SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _text,
                            maxLength: 4000,
                            enabled: !_sending,
                            decoration:
                                const InputDecoration(labelText: 'Mensaje'))),
                    IconButton(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator())
                            : const Icon(Icons.send))
                  ])))
        ]));
  }
}
