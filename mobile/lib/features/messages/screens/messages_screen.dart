import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/widgets/kaza_badges.dart';
import 'chat_detail_screen.dart';

/// 💬 MENSAJES Y VISITAS - Kaza Leads, Chats & Visit Safety
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _realMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRealMessages();
  }

  Future<void> _fetchRealMessages() async {
    try {
      final response = await SupabaseConfig.client
          .from('messages')
          .select('*');
      if (mounted) {
        setState(() {
          _realMessages = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _realMessages = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openChatDetail(String title, String? orgName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(title: title, orgName: orgName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text('Mensajes & Visitas'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KazaTheme.primaryTealLight,
          labelColor: KazaTheme.primaryTealLight,
          unselectedLabelColor: KazaTheme.textMuted,
          tabs: [
            Tab(text: 'Conversaciones (${_realMessages.length})'),
            const Tab(text: 'Citas & Visitas (0)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Conversaciones Chat List
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _realMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 64, color: KazaTheme.primaryTealLight),
                            const SizedBox(height: 16),
                            const Text(
                              'Sin conversaciones aún',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Al comunicarte con un propietario o agente desde un inmueble, tus chats y negociaciones aparecerán aquí.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _realMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _realMessages[index];
                        return _buildChatTile(
                          name: msg['sender_name'] ?? 'Usuario Kaza',
                          subtitle: msg['content'] ?? '',
                          time: 'Hoy',
                          unread: true,
                          isOrgChat: false,
                          orgName: null,
                        );
                      },
                    ),

          // 2. Visitas (Visit Safety) - Limpio en 0
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 64, color: KazaTheme.primaryTealLight),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin visitas programadas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Coordina citas de inspección con protocolo de veracidad y seguridad desde el detalle de cada inmueble.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile({
    required String name,
    required String subtitle,
    required String time,
    required bool unread,
    required bool isOrgChat,
    required String? orgName,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _openChatDetail(name, orgName),
      leading: CircleAvatar(
        backgroundColor: KazaTheme.cardSurface,
        child: Icon(
          isOrgChat ? Icons.business : Icons.person,
          color: KazaTheme.primaryTealLight,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: unread ? FontWeight.w800 : FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: KazaTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOrgChat && orgName != null)
            Text(
              'Org: $orgName',
              style: const TextStyle(color: KazaTheme.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unread ? KazaTheme.textPrimary : KazaTheme.textMuted,
              fontWeight: unread ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
      trailing: unread
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: KazaTheme.primaryTealLight,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
