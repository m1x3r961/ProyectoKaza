import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Seguridad', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seguridad de la cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
            const SizedBox(height: 16),
            _buildSecurityItem(
              icon: Icons.lock_outline,
              title: 'Contraseña',
              subtitle: 'Última actualización: 12 may 2025',
              showArrow: true,
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              icon: Icons.security_outlined,
              title: 'Verificación en dos pasos',
              subtitle: 'Activada',
              trailingIcon: Icons.check_circle,
              trailingColor: KazaTheme.verifiedGreen,
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              icon: Icons.devices,
              title: 'Dispositivos',
              subtitle: '3 dispositivos activos',
              showArrow: true,
            ),
            
            const SizedBox(height: 32),
            const Divider(color: KazaTheme.glassBorder, height: 1),
            const SizedBox(height: 32),
            
            const Text('Accesos rápidos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Iniciar sesión con', style: TextStyle(fontSize: 14, color: KazaTheme.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialLogin('Google'),
                _buildSocialLogin('Apple'),
                _buildSocialLogin('Facebook'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    bool showArrow = false,
    IconData? trailingIcon,
    Color? trailingColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: KazaTheme.glassBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: KazaTheme.textPrimary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: KazaTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
              ],
            ),
          ),
          if (showArrow) const Icon(Icons.chevron_right, color: KazaTheme.textSecondary),
          if (trailingIcon != null) Icon(trailingIcon, color: trailingColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildSocialLogin(String provider) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: KazaTheme.glassBorder),
          ),
          child: const Center(child: Icon(Icons.account_circle, color: KazaTheme.textPrimary)), // Generic placeholder
        ),
        const SizedBox(height: 8),
        Text(provider, style: const TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
      ],
    );
  }
}
