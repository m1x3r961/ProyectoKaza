import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/crm_models.dart';

final crmOpportunitiesProvider = FutureProvider.autoDispose<List<CrmOpportunity>>((ref) async {
  final auth = ref.watch(kazaAuthProvider);
  if (auth.userId == null) return [];
  
  final response = await SupabaseConfig.client
      .from('crm_opportunities')
      .select('*, crm_contacts(*)')
      .order('created_at', ascending: false);
      
  return (response as List).map((x) => CrmOpportunity.fromJson(x)).toList();
});

/// 🎯 EMBUDO DE OPORTUNIDADES (CRM U06)
class CrmOpportunitiesScreen extends ConsumerStatefulWidget {
  const CrmOpportunitiesScreen({super.key});

  @override
  ConsumerState<CrmOpportunitiesScreen> createState() => _CrmOpportunitiesScreenState();
}

class _CrmOpportunitiesScreenState extends ConsumerState<CrmOpportunitiesScreen> {
  String _selectedStage = 'PROSPECTO';
  final List<String> _stages = ['PROSPECTO', 'VISITA', 'NEGOCIACION', 'CIERRE', 'PERDIDO'];

  @override
  Widget build(BuildContext context) {
    final oppsAsync = ref.watch(crmOpportunitiesProvider);

    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: KazaTheme.n000,
        elevation: 0,
        title: const Text('Oportunidades', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: KazaTheme.azulKaza), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Pipeline Stages (Horizontal Scroll)
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
                      color: isSelected ? KazaTheme.azulKaza : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? KazaTheme.azulKaza : KazaTheme.glassBorder),
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
          
          // Opportunities List
          Expanded(
            child: oppsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: KazaTheme.azulKaza)),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (opps) {
                final filtered = opps.where((o) => o.stage == _selectedStage).toList();
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.view_kanban_outlined, size: 80, color: KazaTheme.grisMedio),
                        const SizedBox(height: 16),
                        Text('No hay oportunidades en $_selectedStage', style: const TextStyle(fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final opp = filtered[index];
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
                              Expanded(child: Text(opp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.azulKaza))),
                              Text('USD ${opp.amountExpected.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: KazaTheme.verifiedGreen)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (opp.contact != null)
                            Row(
                              children: [
                                const Icon(Icons.person, size: 14, color: KazaTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(opp.contact!.firstName, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13)),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
