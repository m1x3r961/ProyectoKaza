import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../auth/providers/auth_provider.dart';

class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(kazaAuthProvider);
    final userName = authState.isAuthenticated ? (authState.fullName ?? 'Ana Rodríguez') : 'Ana Rodríguez';
    final userEmail = authState.isAuthenticated ? (authState.email ?? 'ana@kazabienesraices.com') : 'ana@kazabienesraices.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Información personal', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: KazaTheme.textPrimary)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: KazaTheme.grisClaro,
                    child: Icon(Icons.person, size: 40, color: KazaTheme.grisMedio),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_outlined, size: 20, color: KazaTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField('Nombre completo', userName),
            const SizedBox(height: 20),
            _buildTextField('Correo electrónico', userEmail, verified: true),
            const SizedBox(height: 20),
            _buildTextField('Teléfono', '+591 700 12345'),
            const SizedBox(height: 20),
            _buildDropdown('Idioma', 'Español'),
            const SizedBox(height: 20),
            _buildDropdown('País / Región', 'Bolivia'),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, {bool verified = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: KazaTheme.glassBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 15, color: KazaTheme.textPrimary))),
              if (verified) const Icon(Icons.check, color: KazaTheme.azulKaza, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: KazaTheme.glassBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 15, color: KazaTheme.textPrimary)),
              const Icon(Icons.expand_more, color: KazaTheme.textSecondary, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}
