import 'package:flutter/material.dart';
import '../../../../app/theme/kaza_theme.dart';

class CrmMoreTab extends StatelessWidget {
  const CrmMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Administración avanzada', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
        const SizedBox(height: 24),
        _menuItem('Miembros y roles', Icons.people_outline),
        _menuItem('Permisos y alcance', Icons.security),
        _menuItem('Equipos y asignaciones', Icons.group_work_outlined),
        _menuItem('Transferencias y colaboraciones', Icons.swap_horiz),
        _menuItem('Conversaciones', Icons.chat_bubble_outline),
        _menuItem('Visitas', Icons.event_available_outlined),
        _menuItem('Propuestas y operaciones', Icons.gavel_outlined),
        _menuItem('Informes y rendimiento', Icons.insert_chart_outlined),
      ],
    );
  }

  Widget _menuItem(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: KazaTheme.azulKaza.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: KazaTheme.azulKaza, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: KazaTheme.textMuted),
        onTap: () {},
      ),
    );
  }
}
