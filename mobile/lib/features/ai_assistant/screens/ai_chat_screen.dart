import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../widgets/ai_disclaimer_sheet.dart';

/// 08 CHAT CON IMAGINA (MVP de demostración UI)
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Según los datos de los últimos 6 meses, la demanda se mantiene alta y la oferta sigue limitada. Los precios han mostrado una tendencia al alza moderada (14.6% interanual).\n\nFactores clave:\n• Baja oferta disponible\n• Alta demanda para familias\n• Infraestructura en desarrollo\n• Proyectos futuros cercanos',
    }
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _controller.clear();
      
      // Simular respuesta del asistente
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add({
              'isUser': false,
              'text': 'Interesante pregunta. En KAZA Imagina estamos trabajando para conectar con el backend y poder darte respuestas en tiempo real. ¡Pronto estará disponible esta funcionalidad al 100%!',
            });
          });
        }
      });
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
    return Scaffold(
      backgroundColor: KazaTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: KazaTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: KazaTheme.azulKaza, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Chat con Imagina',
              style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: KazaTheme.coralKaza.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('BETA', style: TextStyle(color: KazaTheme.coralKaza, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: KazaTheme.textSecondary),
            onPressed: _showDisclaimer,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de advertencia (Coral)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: KazaTheme.coralKaza.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: KazaTheme.coralKaza, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No tomes decisiones financieras basándote solo en este chat.',
                    style: TextStyle(color: KazaTheme.coralKaza, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                return _buildChatBubble(msg['text'] as String, isUser);
              },
            ),
          ),
          
          // Suggestions (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSuggestionChip('¿Es bueno para alquilar?'),
                _buildSuggestionChip('Proyectos futuros'),
                _buildSuggestionChip('Más datos'),
              ],
            ),
          ),
          
          // Input box
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12 + MediaQuery.of(context).padding.bottom),
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
                    decoration: InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                      hintStyle: const TextStyle(color: KazaTheme.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: KazaTheme.grisClaro,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: KazaTheme.azulKaza,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? KazaTheme.azulKaza : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: KazaTheme.glassBorder),
          boxShadow: isUser ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : KazaTheme.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(text, style: const TextStyle(color: KazaTheme.azulKaza, fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          _controller.text = text;
          _sendMessage();
        },
      ),
    );
  }
}
