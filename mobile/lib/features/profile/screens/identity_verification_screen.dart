import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class IdentityVerificationScreen extends StatelessWidget {
  const IdentityVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Verificación', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shield, size: 100, color: KazaTheme.verifiedGreen.withValues(alpha: 0.15)),
                  const Icon(Icons.check, size: 50, color: KazaTheme.verifiedGreen),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Tu identidad está verificada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: KazaTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Verificado el 15 may 2025', style: TextStyle(fontSize: 14, color: KazaTheme.textSecondary)),
            const SizedBox(height: 48),
            
            _buildVerificationItem(Icons.badge_outlined, 'Documento de identidad', true),
            const SizedBox(height: 16),
            _buildVerificationItem(Icons.phone_outlined, 'Número de teléfono', true),
            
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: KazaTheme.azulKaza),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: KazaTheme.textPrimary, height: 1.5),
                        children: [
                          TextSpan(text: 'La verificación ayuda a generar confianza y mejora tu reputación en la plataforma.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationItem(IconData icon, String title, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: KazaTheme.glassBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: KazaTheme.textPrimary, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: KazaTheme.textPrimary))),
          if (isVerified) 
            const Text('Verificado', style: TextStyle(color: KazaTheme.verifiedGreen, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
