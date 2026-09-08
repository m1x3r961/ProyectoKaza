import 'package:flutter/material.dart';
import '../../../../app/theme/kaza_theme.dart';

class CrmActivityTab extends StatelessWidget {
  const CrmActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildTabs(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              const Text('Hoy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.azulKaza)),
              const SizedBox(height: 12),
              _activityItem('Cristian Vargas', 'agente', 'Casa en Equipetrol Norte', '10:24', Icons.person),
              _activityItem('María Soliz', 'creó una transferencia', 'Depto Urubó Village', '09:45', Icons.swap_horiz),
              _activityItem('Valeria Rocha', 'programó visita', 'Casa Pampa - 15 may', '09:15', Icons.event),
              _activityItem('Diego Suárez', 'respondió un lead', 'Lead #L-2023-0400', '08:50', Icons.message),
              
              const SizedBox(height: 24),
              const Text('Ayer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.azulKaza)),
              const SizedBox(height: 12),
              _activityItem('Javier Higa', 'publicó', 'Casa Las Palmas', '18:20', Icons.home),
              _activityItem('Carla Mendoza', 'invitó a', 'Ana Melgar (Agente)', '17:10', Icons.person_add),
              _activityItem('Sistema', 'generó informe mensual', 'Resumen de rendimiento', '12:30', Icons.insert_chart),
            ],
          ),
        ),
        _buildViewAllBtn(),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text('Actividad', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tab('Todas', true),
          const SizedBox(width: 16),
          _tab('Acciones', false),
          const SizedBox(width: 16),
          _tab('Miembros', false),
          const SizedBox(width: 16),
          _tab('Sistema', false),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? KazaTheme.azulKaza : KazaTheme.textMuted)),
        const SizedBox(height: 4),
        if (active) Container(width: 24, height: 2, color: KazaTheme.primaryCoral),
      ],
    );
  }

  Widget _activityItem(String name, String action, String target, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: KazaTheme.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: KazaTheme.textPrimary),
                    children: [
                      TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' $action '),
                      TextSpan(text: target, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(color: KazaTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildViewAllBtn() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KazaTheme.azulKaza,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {},
        child: const Text('Ver toda la actividad', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
