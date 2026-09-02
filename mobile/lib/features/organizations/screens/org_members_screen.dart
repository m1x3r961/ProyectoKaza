import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

/// 👥 MIEMBROS / EQUIPO (U07 BUSINESS)
class OrgMembersScreen extends StatelessWidget {
  const OrgMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Miembros de la Organización', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: KazaTheme.azulKaza),
            onPressed: () => _showInviteSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildMemberTile('Carlos Méndez', 'Propietario', 'carlos@inmobiliaria.com', KazaTheme.coralKaza),
          const SizedBox(height: 12),
          _buildMemberTile('Lucía Ruiz', 'Administrador', 'lucia@inmobiliaria.com', const Color(0xFF7C4DFF)),
          const SizedBox(height: 12),
          _buildMemberTile('Juan Pérez', 'Agente', 'juan@inmobiliaria.com', KazaTheme.azulKaza),
          const SizedBox(height: 12),
          _buildMemberTile('María Silva', 'Agente', 'maria@inmobiliaria.com', KazaTheme.azulKaza),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C4DFF),
        onPressed: () => _showInviteSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMemberTile(String name, String role, String email, Color roleColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: KazaTheme.n100,
          child: Text(name[0], style: const TextStyle(color: KazaTheme.textSecondary, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(email, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(role, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invitar Miembro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Correo electrónico')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Rol (Ej. Agente, Admin)')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitación enviada'), backgroundColor: KazaTheme.semanticSuccess));
                },
                child: const Text('Enviar Invitación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
