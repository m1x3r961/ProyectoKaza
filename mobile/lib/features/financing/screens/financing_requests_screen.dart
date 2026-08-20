import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/financing_models.dart';

/// 07 TUS SOLICITUDES DESDE KAZA
class FinancingRequestsScreen extends StatefulWidget {
  const FinancingRequestsScreen({super.key});

  @override
  State<FinancingRequestsScreen> createState() => _FinancingRequestsScreenState();
}

class _FinancingRequestsScreenState extends State<FinancingRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FinancingRequest> get _activeRequests {
    return mockRequests.where((r) => r.status != FinancingRequestStatus.approved && r.status != FinancingRequestStatus.rejected).toList();
  }

  List<FinancingRequest> get _completedRequests {
    return mockRequests.where((r) => r.status == FinancingRequestStatus.approved || r.status == FinancingRequestStatus.rejected).toList();
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
          'Mis solicitudes',
          style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: KazaTheme.azulKaza,
          unselectedLabelColor: KazaTheme.textSecondary,
          indicatorColor: KazaTheme.azulKaza,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'En curso'),
            Tab(text: 'Completadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_activeRequests),
          _buildList(_completedRequests),
        ],
      ),
    );
  }

  Widget _buildList(List<FinancingRequest> requests) {
    if (requests.isEmpty) {
      return const Center(
        child: Text('No hay solicitudes en esta sección.', style: TextStyle(color: KazaTheme.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(requests[index]);
      },
    );
  }

  Widget _buildRequestCard(FinancingRequest request) {
    final formatter = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KazaTheme.glassBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: request.entity.brandColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.account_balance, color: request.entity.brandColor, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(request.entity.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary))),
              const Icon(Icons.chevron_right_rounded, color: KazaTheme.textMuted),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Crédito Hipotecario', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(formatter.format(request.requestedAmount), style: const TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          const Divider(height: 1, color: KazaTheme.glassBorder),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: request.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: request.statusColor, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      request.statusLabel,
                      style: TextStyle(color: request.statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'Iniciada ${DateFormat('dd MMM yyyy').format(request.dateSent)}',
                style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
