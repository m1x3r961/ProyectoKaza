import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../providers/ai_chat_provider.dart';
import '../services/ai_service.dart';
import '../widgets/ai_disclaimer_sheet.dart';

/// 08 CHAT CON IMAGINA — Conectado a Google Gemini + Datos reales de Supabase
class AiChatScreen extends ConsumerStatefulWidget {
  /// Mensaje inicial opcional (ej. cuando viene desde el hub con contexto)
  final String? initialMessage;

  const AiChatScreen({super.key, this.initialMessage});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Si viene con un mensaje inicial, enviarlo automáticamente
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(aiChatProvider.notifier)
            .sendMessage(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _typingController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showDisclaimer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiDisclaimerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Auto-scroll cuando llegan mensajes nuevos
    ref.listen(aiChatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: KazaTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: KazaTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: KazaTheme.azulKaza, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Imagina',
              style: TextStyle(
                  color: KazaTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: KazaTheme.coralKaza.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('BETA',
                  style: TextStyle(
                      color: KazaTheme.coralKaza,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: KazaTheme.textSecondary),
            tooltip: 'Nueva conversación',
            onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: KazaTheme.textSecondary),
            onPressed: _showDisclaimer,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner advertencia
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: KazaTheme.coralKaza.withValues(alpha: 0.08),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: KazaTheme.coralKaza, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No tomes decisiones financieras basándote solo en este chat.',
                    style: TextStyle(
                        color: KazaTheme.coralKaza,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length +
                  (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length &&
                    chatState.isLoading) {
                  return _buildTypingIndicator();
                }
                final msg = chatState.messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // Suggestions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSuggestionChip('¿Cuál es el precio promedio en Santa Cruz?'),
                _buildSuggestionChip('¿Es buen momento para comprar?'),
                _buildSuggestionChip('¿Qué barrios son buenos para invertir?'),
                _buildSuggestionChip('Más datos del mercado'),
              ],
            ),
          ),

          // Input box
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: KazaTheme.glassBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !chatState.isLoading,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: chatState.isLoading
                          ? 'Imagina está pensando...'
                          : 'Pregunta sobre el mercado boliviano...',
                      hintStyle:
                          const TextStyle(color: KazaTheme.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: KazaTheme.grisClaro,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: chatState.isLoading
                        ? KazaTheme.textMuted
                        : KazaTheme.azulKaza,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: chatState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white),
                    onPressed: chatState.isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: KazaTheme.glassBorder),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: KazaTheme.azulKaza, size: 14),
            const SizedBox(width: 8),
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(150),
            const SizedBox(width: 4),
            _buildDot(300),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: _typingController,
          builder: (context, _) {
            final offset = ((_typingController.value + delayMs / 900) % 1.0);
            final opacity = offset < 0.5 ? offset * 2 : (1.0 - offset) * 2;
            return Opacity(
              opacity: opacity.clamp(0.3, 1.0),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: KazaTheme.azulKaza,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final isError = msg.isError;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isError
              ? KazaTheme.coralKaza.withValues(alpha: 0.08)
              : isUser
                  ? KazaTheme.azulKaza
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isError
                      ? KazaTheme.coralKaza.withValues(alpha: 0.3)
                      : KazaTheme.glassBorder),
          boxShadow: isUser
              ? null
              : const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isError
                          ? Icons.warning_amber_rounded
                          : Icons.auto_awesome_rounded,
                      color: isError
                          ? KazaTheme.coralKaza
                          : KazaTheme.azulKaza,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isError ? 'Error' : 'Imagina',
                      style: TextStyle(
                        color: isError
                            ? KazaTheme.coralKaza
                            : KazaTheme.azulKaza,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : isError
                        ? KazaTheme.coralKaza
                        : KazaTheme.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(text,
            style: const TextStyle(
                color: KazaTheme.azulKaza,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.3)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          _controller.text = text;
          _sendMessage();
        },
      ),
    );
  }
}
