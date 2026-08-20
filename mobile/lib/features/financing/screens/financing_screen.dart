import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/financing_models.dart';
import '../widgets/entity_detail_sheet.dart';

/// 01 CÓMO FUNCIONA / 02 ELIGE TU ENTIDAD
/// Directorio de Entidades Financieras
class FinancingScreen extends StatefulWidget {
  const FinancingScreen({super.key});

  @override
  State<FinancingScreen> createState() => _FinancingScreenState();
}

class _FinancingScreenState extends State<FinancingScreen> {
  String _selectedFilter = 'Todas';
  final List<String> _filters = ['Todas', 'Bancos', 'Cooperativas', 'Financieras', 'Gobierno'];

  List<FinancialEntity> get _filteredEntities {
    if (_selectedFilter == 'Todas') return mockEntities;
    final typeMapping = {
      'Bancos': FinancialEntityType.bank,
      'Cooperativas': FinancialEntityType.cooperative,
      'Financieras': FinancialEntityType.financial,
      'Gobierno': FinancialEntityType.government,
    };
    final type = typeMapping[_selectedFilter];
    return mockEntities.where((e) => e.type == type).toList();
  }

  void _showEntityDetail(FinancialEntity entity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EntityDetailSheet(entity: entity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: KazaTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Financiamiento',
          style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ELIGE TU ENTIDAD FINANCIERA',
                    style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tasas y condiciones referenciales. Verifica siempre en el sitio oficial de cada entidad.',
                    style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // Filtros
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(filter, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : KazaTheme.textPrimary)),
                            selected: isSelected,
                            selectedColor: KazaTheme.azulKaza,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSelected ? KazaTheme.azulKaza : KazaTheme.glassBorder),
                            onSelected: (bool selected) {
                              if (selected) setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Table Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Expanded(flex: 3, child: Text('Entidad', style: TextStyle(color: KazaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Tasa referencial (anual)', style: TextStyle(color: KazaTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        const Expanded(flex: 2, child: Text('Plazo (máx.)', style: TextStyle(color: KazaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        const Expanded(flex: 1, child: SizedBox.shrink()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          // Lista de entidades
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entity = _filteredEntities[index];
                  return _buildEntityCard(entity);
                },
                childCount: _filteredEntities.length,
              ),
            ),
          ),

          // Sección Educativa "LO QUE DEBES SABER"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LO QUE DEBES SABER',
                    style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                  ),
                  const SizedBox(height: 24),
                  _buildEducationalItem(Icons.handshake_outlined, 'KAZA te conecta', 'Somos un puente de conexión. No somos la entidad financiera.'),
                  _buildEducationalItem(Icons.account_balance_outlined, 'Entidad responsable', 'La entidad financiera es la única responsable de evaluar, aprobar y desembolsar el crédito.'),
                  _buildEducationalItem(Icons.percent_rounded, 'Tasas referenciales', 'Las tasas son referenciales y pueden cambiar. Verifica siempre en el sitio oficial.'),
                  _buildEducationalItem(Icons.lock_outline_rounded, 'Tu información, tu control', 'Solo compartimos la información necesaria y con tu autorización.'),
                  _buildEducationalItem(Icons.shield_outlined, 'Sin influencia en tu perfil', 'Usar esta sección no afecta tu reputación, confianza ni acceso a KAZA.'),
                  
                  const SizedBox(height: 40),
                  
                  // Disclaimer bottom
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KazaTheme.azulKaza.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KazaTheme.azulKaza.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: KazaTheme.azulKaza, size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text('NO ES ASESORAMIENTO FINANCIERO', style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'La información es referencial y no constituye recomendación financiera. Verifica siempre con la entidad.',
                          style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, color: KazaTheme.verifiedGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12),
                                  children: [
                                    TextSpan(text: 'KAZA INFORMA, TÚ DECIDES. ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: 'KAZA te da información para decidir. Tú eliges con quién y cómo avanzar.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityCard(FinancialEntity entity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KazaTheme.glassBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEntityDetail(entity),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: entity.brandColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(Icons.account_balance, color: entity.brandColor, size: 20), // Fallback logo
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entity.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KazaTheme.textPrimary))),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${entity.referenceRate.toStringAsFixed(2)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary), textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${entity.maxTermYears} años', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                ),
                const Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.chevron_right_rounded, color: KazaTheme.azulKaza),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEducationalItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: KazaTheme.glassBorder),
            ),
            child: Icon(icon, color: KazaTheme.azulKaza, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: KazaTheme.textPrimary, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
