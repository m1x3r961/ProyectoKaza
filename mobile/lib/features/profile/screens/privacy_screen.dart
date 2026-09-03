import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Permisos y privacidad', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Permisos de la app', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 16),
          _buildPermissionRow(Icons.location_on_outlined, 'Ubicación', 'Siempre'),
          _buildPermissionRow(Icons.camera_alt_outlined, 'Cámara', 'Al usar la app'),
          _buildPermissionRow(Icons.photo_outlined, 'Fotos', 'Al usar la app'),
          _buildPermissionRow(Icons.contacts_outlined, 'Contactos', 'No permitido'),
          _buildPermissionRow(Icons.mic_none, 'Micrófono', 'Al usar la app'),
          
          const SizedBox(height: 32),
          const Divider(color: KazaTheme.glassBorder, height: 1),
          const SizedBox(height: 32),
          
          const Text('Privacidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 16),
          _buildPrivacyRow('Quién puede ver mi perfil', 'Todos'),
          _buildPrivacyRow('Quién puede contactarme', 'Todos'),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: KazaTheme.textPrimary, size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 15, color: KazaTheme.textPrimary)),
            ],
          ),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more, color: KazaTheme.textSecondary, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, color: KazaTheme.textPrimary)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more, color: KazaTheme.textSecondary, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
