import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Eliminar o desactivar cuenta', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOptionCard(
              icon: Icons.pause_circle_outline,
              title: 'Desactivar cuenta',
              subtitle: 'Tu perfil y publicaciones se ocultarán temporalmente.',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.delete_outline,
              title: 'Eliminar cuenta',
              subtitle: 'Se eliminarán tus datos y no podrás recuperarlos.',
              iconColor: Colors.redAccent,
              titleColor: Colors.redAccent,
              onTap: () {},
            ),
            
            const Spacer(),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Antes de eliminar tu cuenta:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildWarningBullet('Descarga tu información si lo necesitas.'),
                  const SizedBox(height: 4),
                  _buildWarningBullet('Elige desactivar si solo tomarás un descanso.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap,
    Color iconColor = KazaTheme.textPrimary,
    Color titleColor = KazaTheme.textPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: KazaTheme.glassBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: titleColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: KazaTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
      ],
    );
  }
}
