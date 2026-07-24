import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          tabs: const [
            Tab(text: 'Conversaciones (2)'),
            Tab(text: 'Citas & Visitas (1)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Conversaciones Chat List
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChatTile(
                name: 'Carlos Mendoza',
                subtitle: 'Consulta sobre Dpto. Equipetrol: "¿Acepta financiamiento bancario?"',
                time: '10:42 AM',
                unread: true,
                isOrgChat: true,
                orgName: 'Inmobiliaria Kaza Pro',
              ),
              const Divider(color: KazaTheme.glassBorder),
              _buildChatTile(
                name: 'Ana Gutiérrez (Propietaria)',
                subtitle: 'Confirmado para la visita de mañana a las 3:00 PM',
                time: 'Ayer',
                unread: false,
                isOrgChat: false,
                orgName: null,
              ),
            ],
          ),

          // 2. Visitas (Visit Safety)
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security, color: KazaTheme.primaryTealLight, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Visit Safety Protocol',
                            style: TextStyle(fontWeight: FontWeight.bold, color: KazaTheme.primaryTealLight),
                          ),
                          const Spacer(),
                          const KazaStatusBadge(status: 'CONFIRMED'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Visita Programada: Casa Moderna en Urubó West',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '📅 Mañana, 25 de Julio · 15:00 PM',
                        style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '👤 Coordinada con: Ana Gutiérrez',
                        style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                      ),
                      const Divider(height: 24, color: KazaTheme.glassBorder),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.share, size: 16),
                              label: const Text('Compartir Cita'),
                              onPressed: () {
                                _openChatDetail('Carlos Mendoza', 'Inmobiliaria Kaza Pro');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KazaTheme.primaryTeal,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.location_on, size: 16),
                              label: const Text('Abrir Chat'),
                              onPressed: () {
                                _openChatDetail('Carlos Mendoza', 'Inmobiliaria Kaza Pro');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
