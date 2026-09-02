import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

/// 🎯 OPORTUNIDADES (U07 BUSINESS) - Embudo Consolidado
class OrgOpportunitiesScreen extends StatefulWidget {
  const OrgOpportunitiesScreen({super.key});

  @override
  State<OrgOpportunitiesScreen> createState() => _OrgOpportunitiesScreenState();
}

class _OrgOpportunitiesScreenState extends State<OrgOpportunitiesScreen> {
  String _selectedStage = 'PROSPECTO';
  final List<String> _stages = ['PROSPECTO', 'VISITA', 'NEGOCIACION', 'CIERRE', 'PERDIDO'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Pipeline Consolidado', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Pipeline Stages
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: _stages.map((stage) {
                final isSelected = _selectedStage == stage;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStage = stage),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C4DFF) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? const Color(0xFF7C4DFF) : KazaTheme.glassBorder),
                    ),
                    child: Text(
                      stage,
                      style: TextStyle(
                        color: isSelected ? Colors.white : KazaTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: KazaTheme.glassBorder, height: 1),
          
          // Opportunities List (Mocked for Phase 3)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildOpportunityCard('Familia Suárez - Casa Urubó', 'USD 350.000', 'Agente: Juan Pérez'),
                const SizedBox(height: 12),
                _buildOpportunityCard('Inversor Extranjero - Deptos', 'USD 120.000', 'Agente: María Silva'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(String title, String amount, String agent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7C4DFF)))),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: KazaTheme.verifiedGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: KazaTheme.textSecondary),
              const SizedBox(width: 4),
              Text(agent, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
