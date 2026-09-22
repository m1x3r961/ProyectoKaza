import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../organizations/screens/crm/properties/crm_projects_dashboard.dart';

/// 📈 KAZA INVEST SCREEN — "05 KAZA Invest (inicio)"
/// Inversiones inmobiliarias de forma simple y transparente.
/// Pantalla de oportunidades de inversión con ROI, rentabilidad y proyectos.
class KazaInvestScreen extends ConsumerStatefulWidget {
  const KazaInvestScreen({super.key});

  @override
  ConsumerState<KazaInvestScreen> createState() => _KazaInvestScreenState();
}

class _KazaInvestScreenState extends ConsumerState<KazaInvestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  final List<_InvestOpportunity> _opportunities = [
    _InvestOpportunity(
      title: 'Torre Los Mangales',
      location: 'Equipetrol, Santa Cruz',
      imageGradient: [Color(0xFF1A3A5C), Color(0xFF2A6496)],
      totalReturn: 40,
      rentaAnual: 7.8,
      minimumInvestment: 7800000,
      status: 'EN PREVENTA',
      statusColor: Color(0xFFFF5A3C),
      progress: 0.62,
      category: 'Departamentos',
      area: 85,
      floors: 18,
    ),
    _InvestOpportunity(
      title: 'Distrito Norte',
      location: 'Zona Norte, Santa Cruz',
      imageGradient: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
      totalReturn: 35,
      rentaAnual: 6.5,
      minimumInvestment: 10500000,
      status: 'EN PREVENTA',
      statusColor: Color(0xFFFF5A3C),
      progress: 0.45,
      category: 'Oficinas',
      area: 120,
      floors: 24,
    ),
    _InvestOpportunity(
      title: 'Vive Urubo',
      location: 'Urubo, Santa Cruz',
      imageGradient: [Color(0xFF4A1942), Color(0xFF6B2D5E)],
      totalReturn: 28,
      rentaAnual: 5.2,
      minimumInvestment: 5000000,
      status: 'EN CONSTRUCCIÓN',
      statusColor: Color(0xFFF59E0B),
      progress: 0.78,
      category: 'Casas',
      area: 200,
      floors: 2,
    ),
    _InvestOpportunity(
      title: 'Centro Comercial Urbarí',
      location: 'Urbarí, Santa Cruz',
      imageGradient: [Color(0xFF1A237E), Color(0xFF283593)],
      totalReturn: 55,
      rentaAnual: 9.1,
      minimumInvestment: 25000000,
      status: 'OPORTUNIDAD',
      statusColor: Color(0xFF2CA754),
      progress: 0.30,
      category: 'Comercial',
      area: 350,
      floors: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);
    final tierAsync = ref.watch(userTierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: roleAsync.when(
        data: (role) {
          return tierAsync.when(
            data: (tier) {
              if (role == 'DEVELOPER' || tier == 'PROPERTIES' || tier == 'BUSINESS') {
                return const CrmProjectsDashboard();
              } else {
                return _buildAccessDeniedMessage();
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAccessDeniedMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: KazaTheme.grisMedio),
            const SizedBox(height: 24),
            const Text(
              'Acceso Exclusivo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta sección está reservada para Desarrolladoras de Proyectos Inmobiliarios.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KazaTheme.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.coralKaza,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Conocer más', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumerInvest() {
    return CustomScrollView(
      slivers: [
          // ── HEADER ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: KazaTheme.azulKaza,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F1F2E), Color(0xFF1A3A5C)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: KazaTheme.coralKaza.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: KazaTheme.coralKaza.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                      color: KazaTheme.coralKaza,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'KAZA Invest',
                                    style: TextStyle(
                                      color: KazaTheme.coralKaza,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Inversiones\ninmobiliarias',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'De forma simple y transparente.',
                          style: TextStyle(
                            color: Color(0xFFB0C4D8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: KazaTheme.azulKaza,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF7A9AB8),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  indicatorColor: KazaTheme.coralKaza,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Oportunidades'),
                    Tab(text: 'Mis inversiones'),
                    Tab(text: 'Aprende'),
                  ],
                ),
              ),
            ),
          ),

          // ── METRICS SUMMARY ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _MetricCard(
                    label: 'ROI Promedio',
                    value: '7.8%',
                    sublabel: 'Renta anual',
                    color: const Color(0xFF2CA754),
                    icon: Icons.trending_up_rounded,
                  ),
                  const SizedBox(width: 12),
                  _MetricCard(
                    label: 'En preventa',
                    value: '4',
                    sublabel: 'Proyectos activos',
                    color: KazaTheme.coralKaza,
                    icon: Icons.apartment_rounded,
                  ),
                  const SizedBox(width: 12),
                  _MetricCard(
                    label: 'Retorno total',
                    value: '+40%',
                    sublabel: 'Máx. proyectado',
                    color: const Color(0xFF7C3AED),
                    icon: Icons.bar_chart_rounded,
                  ),
                ],
              ),
            ),
          ),

          // ── SECTION TITLE ────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Oportunidades destacadas',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: KazaTheme.azulKaza,
                    ),
                  ),
                  Text(
                    'Ver todas',
                    style: TextStyle(
                      color: KazaTheme.coralKaza,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── OPPORTUNITY CARDS ─────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final opp = _opportunities[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _OpportunityCard(opportunity: opp),
                );
              },
              childCount: _opportunities.length,
            ),
          ),

          // ── BOTTOM SPACE ─────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _InvestOpportunity {
  final String title;
  final String location;
  final List<Color> imageGradient;
  final int totalReturn;
  final double rentaAnual;
  final int minimumInvestment;
  final String status;
  final Color statusColor;
  final double progress;
  final String category;
  final int area;
  final int floors;

  const _InvestOpportunity({
    required this.title,
    required this.location,
    required this.imageGradient,
    required this.totalReturn,
    required this.rentaAnual,
    required this.minimumInvestment,
    required this.status,
    required this.statusColor,
    required this.progress,
    required this.category,
    required this.area,
    required this.floors,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// METRIC CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(
                color: KazaTheme.grisMedio,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPPORTUNITY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _OpportunityCard extends StatelessWidget {
  final _InvestOpportunity opportunity;

  const _OpportunityCard({required this.opportunity});

  String _formatPrice(int val) {
    if (val >= 1000000) {
      final m = val / 1000000;
      return 'Bs ${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    return 'Bs $val';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image area with gradient
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: opportunity.imageGradient,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -20, top: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20, bottom: -30,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Building icon
                    Center(
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: opportunity.statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    opportunity.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              // ROI Badge
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Color(0xFF4ADE80), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+${opportunity.totalReturn}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Category badge bottom
              Positioned(
                bottom: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    opportunity.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Location
                Text(
                  opportunity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: KazaTheme.azulKaza,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: KazaTheme.grisMedio),
                    const SizedBox(width: 3),
                    Text(
                      opportunity.location,
                      style: const TextStyle(
                        color: KazaTheme.grisMedio,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrics row
                Row(
                  children: [
                    _InvestMetric(
                      label: 'Renta anual',
                      value: '${opportunity.rentaAnual}%',
                      color: const Color(0xFF2CA754),
                    ),
                    const SizedBox(width: 16),
                    _InvestMetric(
                      label: 'Inversión mín.',
                      value: _formatPrice(opportunity.minimumInvestment),
                      color: KazaTheme.azulKaza,
                    ),
                    const SizedBox(width: 16),
                    _InvestMetric(
                      label: 'Área',
                      value: '${opportunity.area}m²',
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Financiación',
                          style: TextStyle(
                            color: KazaTheme.grisMedio,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(opportunity.progress * 100).toInt()}% completado',
                          style: const TextStyle(
                            color: KazaTheme.azulKaza,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: opportunity.progress,
                        backgroundColor: const Color(0xFFE8EDF2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          opportunity.statusColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KazaTheme.azulKaza,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Ver oportunidad',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InvestMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: KazaTheme.grisMedio,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
