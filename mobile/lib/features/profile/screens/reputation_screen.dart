import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class ReputationScreen extends StatelessWidget {
  const ReputationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Logros y reputación', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reputación general', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('4.8', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 48, color: KazaTheme.textPrimary)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.star, color: KazaTheme.accentGold, size: 20),
                        Icon(Icons.star, color: KazaTheme.accentGold, size: 20),
                        Icon(Icons.star, color: KazaTheme.accentGold, size: 20),
                        Icon(Icons.star, color: KazaTheme.accentGold, size: 20),
                        Icon(Icons.star_half, color: KazaTheme.accentGold, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Basado en 128 calificaciones', style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRatingBar(5, 0.78, '78%'),
            _buildRatingBar(4, 0.16, '16%'),
            _buildRatingBar(3, 0.04, '4%'),
            _buildRatingBar(2, 0.01, '1%'),
            _buildRatingBar(1, 0.01, '1%'),
            
            const SizedBox(height: 40),
            const Text('Logros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAchievement(Icons.verified, 'Verificado', true),
                _buildAchievement(Icons.rocket_launch, 'Publicador\nactivo', true),
                _buildAchievement(Icons.bolt, 'Responde\nrápido', true),
                _buildAchievement(Icons.stars, 'Visitas\nconfirmadas', false),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Ver todos los logros', style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$stars ★', style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: KazaTheme.glassBorder,
              color: KazaTheme.textPrimary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(label, style: const TextStyle(fontSize: 12, color: KazaTheme.textSecondary), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(IconData icon, String title, bool achieved) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: achieved ? Colors.transparent : KazaTheme.grisClaro,
            border: Border.all(color: achieved ? KazaTheme.azulKaza : Colors.transparent, width: 2),
          ),
          child: Icon(icon, color: achieved ? KazaTheme.azulKaza : KazaTheme.grisMedio, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title, 
          textAlign: TextAlign.center, 
          style: TextStyle(
            fontSize: 11, 
            color: achieved ? KazaTheme.textPrimary : KazaTheme.textSecondary,
            fontWeight: achieved ? FontWeight.bold : FontWeight.normal
          )
        ),
      ],
    );
  }
}
