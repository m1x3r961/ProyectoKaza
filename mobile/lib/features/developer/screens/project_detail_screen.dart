import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/developer_models.dart';
import '../providers/developer_provider.dart';

/// 📋 DETALLE DE PROYECTO (U08)
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final DevProject project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DevUnit> _units = [];
  List<DevProjectStage> _stages = [];
  List<DevDocument> _docs = [];
  List<DevFinancialRecord> _financials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final notifier = ref.read(developerProvider.notifier);
    final pid = widget.project.id;
    final results = await Future.wait([
      notifier.loadUnits(pid),
      notifier.loadStages(pid),
      notifier.loadDocuments(pid),
      notifier.loadFinancials(pid),
    ]);
    if (mounted) {
      setState(() {
        _units = results[0] as List<DevUnit>;
        _stages = results[1] as List<DevProjectStage>;
        _docs = results[2] as List<DevDocument>;
        _financials = results[3] as List<DevFinancialRecord>;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  pinned: true,
                  expandedHeight: 220,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: KazaTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text('${p.projectType} • ${p.city ?? ""}', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
                          const SizedBox(height: 12),
                          // Métricas rápidas
                          Row(
                            children: [
                              _buildQuickStat('Avance', '${p.progressPct.toStringAsFixed(1)}%'),
                              const SizedBox(width: 16),
                              _buildQuickStat('Vendidas', '${p.soldUnits}/${p.totalUnits}'),
                              const SizedBox(width: 16),
                              _buildQuickStat('Inversión', '\$${_formatNumber(p.estimatedInvestment)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    labelColor: KazaTheme.textPrimary,
                    unselectedLabelColor: KazaTheme.textMuted,
                    indicatorColor: KazaTheme.coralKaza,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Unidades'),
                      Tab(text: 'Etapas'),
                      Tab(text: 'Finanzas'),
                      Tab(text: 'Docs'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildUnitsTab(),
                  _buildStagesTab(),
                  _buildFinancialsTab(),
                  _buildDocsTab(),
                ],
              ),
            ),
    );
  }

  // ── TAB 1: UNIDADES ────────────────────────────────────────
  Widget _buildUnitsTab() {
    if (_units.isEmpty) return const Center(child: Text('Sin unidades registradas'));
    final disponibles = _units.where((u) => u.status == 'DISPONIBLE').length;
    final reservadas = _units.where((u) => u.status == 'RESERVADA').length;
    final vendidas = _units.where((u) => u.status == 'VENDIDA').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen
        Row(
          children: [
            Expanded(child: _buildUnitStat('Disponibles', '$disponibles', KazaTheme.verifiedGreen)),
            const SizedBox(width: 8),
            Expanded(child: _buildUnitStat('Reservadas', '$reservadas', KazaTheme.statusReserved)),
            const SizedBox(width: 8),
            Expanded(child: _buildUnitStat('Vendidas', '$vendidas', KazaTheme.statusClosed)),
          ],
        ),
        const SizedBox(height: 16),
        ..._units.map((u) => _buildUnitTile(u)),
      ],
    );
  }

  Widget _buildUnitTile(DevUnit unit) {
    final color = _unitStatusColor(unit.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(unit.unitCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${unit.typology} • ${unit.areaM2.toStringAsFixed(0)} m²', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                if (unit.bedrooms > 0)
                  Text('${unit.bedrooms} hab • ${unit.bathrooms} baños • Piso ${unit.floorNumber}', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
                if (unit.buyerName != null)
                  Text('Comprador: ${unit.buyerName}', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_formatNumber(unit.priceUsd)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(unit.status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 2: ETAPAS ──────────────────────────────────────────
  Widget _buildStagesTab() {
    if (_stages.isEmpty) return const Center(child: Text('Sin etapas registradas'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _stages.map((s) => _buildStageTile(s)).toList(),
    );
  }

  Widget _buildStageTile(DevProjectStage stage) {
    final color = stage.status == 'COMPLETADA' ? KazaTheme.verifiedGreen
        : stage.status == 'EN_PROGRESO' ? KazaTheme.coralKaza
        : KazaTheme.textMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(child: Text('${stage.stageOrder}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(stage.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: KazaTheme.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(stage.status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: stage.progressPct / 100, backgroundColor: KazaTheme.glassBorder, color: color, minHeight: 6),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${stage.progressPct.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: FINANZAS ────────────────────────────────────────
  Widget _buildFinancialsTab() {
    if (_financials.isEmpty) return const Center(child: Text('Sin registros financieros'));
    final ingresos = _financials.where((f) => f.recordType == 'INGRESO').fold(0.0, (sum, f) => sum + f.amount);
    final egresos = _financials.where((f) => f.recordType == 'EGRESO').fold(0.0, (sum, f) => sum + f.amount);
    final utilidad = ingresos - egresos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildFinStat('Ingresos', '\$${_formatNumber(ingresos)}', KazaTheme.verifiedGreen)),
            const SizedBox(width: 8),
            Expanded(child: _buildFinStat('Egresos', '\$${_formatNumber(egresos)}', KazaTheme.statusClosed)),
            const SizedBox(width: 8),
            Expanded(child: _buildFinStat('Utilidad', '\$${_formatNumber(utilidad)}', utilidad >= 0 ? KazaTheme.azulKaza : KazaTheme.statusClosed)),
          ],
        ),
        const SizedBox(height: 16),
        ..._financials.map((f) => _buildFinancialTile(f)),
      ],
    );
  }

  Widget _buildFinancialTile(DevFinancialRecord record) {
    final isIngreso = record.recordType == 'INGRESO';
    final color = isIngreso ? KazaTheme.verifiedGreen : KazaTheme.statusClosed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: KazaTheme.glassBorder)),
      child: Row(
        children: [
          Icon(isIngreso ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.description ?? record.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                Text('${record.category} • ${record.recordDate?.toString().substring(0, 10) ?? ""}', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text('${isIngreso ? "+" : "-"}\$${_formatNumber(record.amount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  // ── TAB 4: DOCUMENTOS ──────────────────────────────────────
  Widget _buildDocsTab() {
    if (_docs.isEmpty) return const Center(child: Text('Sin documentos'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _docs.map((d) => _buildDocTile(d)).toList(),
    );
  }

  Widget _buildDocTile(DevDocument doc) {
    final icon = _docTypeIcon(doc.docType);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: KazaTheme.glassBorder)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: KazaTheme.azulKaza.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: KazaTheme.azulKaza, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                Text(doc.docType, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.download_outlined, color: KazaTheme.textMuted),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _buildQuickStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
      ],
    );
  }

  Widget _buildUnitStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildFinStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: KazaTheme.glassBorder)),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Color _unitStatusColor(String status) {
    switch (status) {
      case 'DISPONIBLE': return KazaTheme.verifiedGreen;
      case 'RESERVADA': return KazaTheme.statusReserved;
      case 'VENDIDA': return KazaTheme.statusClosed;
      case 'ENTREGADA': return KazaTheme.azulKaza;
      default: return KazaTheme.textMuted;
    }
  }

  IconData _docTypeIcon(String docType) {
    switch (docType) {
      case 'PLANO': return Icons.architecture;
      case 'PERMISO': return Icons.gavel;
      case 'CONTRATO': return Icons.description;
      case 'INFORME': return Icons.assessment;
      default: return Icons.insert_drive_file;
    }
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }
}
