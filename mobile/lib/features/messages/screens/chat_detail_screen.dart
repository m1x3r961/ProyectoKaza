import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../providers/chat_provider.dart';

/// 💬 CHAT DETAIL & VISIT SAFETY SCREEN
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String title;
  final String? orgName;

  const ChatDetailScreen({
    super.key,
    required this.title,
    this.orgName,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (widget.orgName != null)
              Text(
                'Org: ${widget.orgName}',
                style: const TextStyle(fontSize: 11, color: KazaTheme.accentGold, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Visit Safety Top Protocol Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: KazaTheme.cardSurface,
              border: Border(bottom: BorderSide(color: KazaTheme.glassBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, color: KazaTheme.primaryTealLight, size: 18),
                    const SizedBox(width: 6),
                    const Text('Visit Safety Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KazaTheme.primaryTealLight)),
                    const Spacer(),
                    KazaStatusBadge(status: chatState.visitStatus ?? 'CONFIRMED'),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cita de Visita: Mañana · 15:00 PM (Dpto. Equipetrol)',
                  style: TextStyle(color: KazaTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          side: const BorderSide(color: KazaTheme.glassBorder),
                        ),
                        icon: const Icon(Icons.share, size: 14),
                        label: const Text('Compartir Cita', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📲 Cita de visita compartida con tu contacto de seguridad'),
                              backgroundColor: KazaTheme.primaryTeal,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: chatState.visitStatus == 'CHECKED_IN' ? KazaTheme.verifiedGreen : KazaTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        icon: Icon(chatState.visitStatus == 'CHECKED_IN' ? Icons.check_circle : Icons.location_on, size: 14),
                        label: Text(
                          chatState.visitStatus == 'CHECKED_IN' ? 'Checked-In' : 'Hacer Check-In',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          ref.read(chatProvider.notifier).performVisitCheckIn();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Check-In de visita confirmado. Notificado a la organización.'),
                              backgroundColor: KazaTheme.verifiedGreen,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // 3. Bottom Text Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: KazaTheme.cardSurface,
              border: Border(top: BorderSide(color: KazaTheme.glassBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: KazaTheme.textMuted, fontSize: 14),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: KazaTheme.primaryTealLight),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(KazaMessageItem msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? KazaTheme.primaryTeal : KazaTheme.cardSurface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !msg.isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          border: Border.all(color: msg.isMe ? KazaTheme.primaryTealLight : KazaTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isMe)
              Text(
                msg.senderName,
                style: const TextStyle(color: KazaTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 2),
            Text(
              msg.content,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
