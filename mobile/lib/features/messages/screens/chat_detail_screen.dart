import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
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
  final _focus = FocusNode();
  bool _sending = false;
  String? _error;
  String? _attemptText;
  String _clientId = ApiClient.newId();

  static const _suggestions = [
    '¿Sigue disponible?',
    '¿Puedo agendar una visita?',
    '¿El precio es negociable?',
  ];

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    // Same text keeps the same idempotency id, so a retry never duplicates.
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
      if (mounted) {
        setState(() => _error = 'No se pudo enviar. Revisa tu conexión y toca enviar de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (d.year == now.year && d.month == now.month && d.day == now.day) return hm;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $hm';
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(conversationMessagesProvider(widget.conversationId));
    final me = SupabaseConfig.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: KazaTheme.grisClaro,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: KazaTheme.azulKaza,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: KazaTheme.coralKaza.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_work_outlined, size: 20, color: KazaTheme.coralKaza),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: KazaTheme.azulKaza)),
                  Text(widget.orgName ?? 'Conversación sobre esta propiedad',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: KazaTheme.azulKaza.withValues(alpha: 0.06)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator(color: KazaTheme.coralKaza)),
              error: (e, s) => Center(
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(conversationMessagesProvider(widget.conversationId)),
                  icon: const Icon(Icons.refresh_rounded, color: KazaTheme.coralKaza),
                  label: const Text('No se pudieron cargar los mensajes. Reintentar',
                      style: TextStyle(color: KazaTheme.azulKaza)),
                ),
              ),
              data: (rows) {
                final pending = _sending && _attemptText != null;
                if (rows.isEmpty && !pending) return _emptyState();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  itemCount: rows.length + (pending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (pending && i == 0) {
                      return _bubble(_attemptText!, mine: true, time: 'Enviando…', faded: true);
                    }
                    final m = rows[pending ? i - 1 : i];
                    return _bubble(m['content'] as String? ?? '',
                        mine: m['sender_user_id'] == me, time: _time(m['created_at']));
                  },
                );
              },
            ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          _composer(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: KazaTheme.coralKaza.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 34, color: KazaTheme.coralKaza),
            ),
            const SizedBox(height: 16),
            const Text('Inicia la conversación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
            const SizedBox(height: 6),
            const Text('Escribe al anunciante. La conversación queda guardada en KAZA.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: KazaTheme.textSecondary, height: 1.4)),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _suggestions
                  .map((s) => ActionChip(
                        label: Text(s),
                        labelStyle: const TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.w600),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        onPressed: () {
                          _text.text = s;
                          _text.selection = TextSelection.collapsed(offset: s.length);
                          _focus.requestFocus();
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String text, {required bool mine, required String time, bool faded = false}) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: faded ? 0.6 : 1,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? KazaTheme.coralKaza : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            boxShadow: mine
                ? null
                : [BoxShadow(color: KazaTheme.azulKaza.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(text,
                  style: TextStyle(
                      fontSize: 15, height: 1.35, color: mine ? Colors.white : KazaTheme.azulKaza)),
              if (time.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(time,
                    style: TextStyle(
                        fontSize: 11,
                        color: mine ? Colors.white.withValues(alpha: 0.8) : KazaTheme.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    final canSend = _text.text.trim().isNotEmpty && !_sending;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 15, color: KazaTheme.azulKaza),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje…',
                    hintStyle: const TextStyle(color: KazaTheme.grisMedio),
                    counterText: '',
                    filled: true,
                    fillColor: KazaTheme.grisClaro,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: canSend ? KazaTheme.coralKaza : KazaTheme.azulKaza.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: canSend ? _send : null,
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: KazaTheme.coralKaza))
                          : Icon(Icons.send_rounded,
                              size: 20, color: canSend ? Colors.white : KazaTheme.grisMedio),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
