import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/kaza_theme.dart';
import '../../../models/project_model.dart';
import 'crm_availability_matrix.dart';

class CrmProjectDetailScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const CrmProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<CrmProjectDetailScreen> createState() => _CrmProjectDetailScreenState();
}

class _CrmProjectDetailScreenState extends ConsumerState<CrmProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: KazaTheme.azulKaza,
        foregroundColor: Colors.white,
        title: Text(widget.project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: KazaTheme.coralKaza,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Disponibilidad'),
            Tab(text: 'Compradores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          CrmAvailabilityMatrix(projectId: widget.project.id),
          const Center(child: Text('CRM de Compradores (Leads y Reservas)')),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoCard('Unidades Totales', widget.project.totalUnits.toString(), Icons.apartment)),
            const SizedBox(width: 12),
            Expanded(child: _buildInfoCard('Vendidas', widget.project.soldUnits.toString(), Icons.check_circle_outline)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Disponibles', widget.project.availableUnits.toString(), Icons.event_available)),
            const SizedBox(width: 12),
            Expanded(child: _buildInfoCard('Reservadas', widget.project.reservedUnits.toString(), Icons.access_time)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Velocidad de Absorción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Center(child: Text('Gráfico de Ventas Mensuales')),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KazaTheme.textMuted, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
          Text(title, style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
