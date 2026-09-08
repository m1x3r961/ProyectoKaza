import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import 'crm/crm_resume_tab.dart';
import 'crm/crm_pipeline_tab.dart';
import 'crm/crm_activity_tab.dart';
import 'crm/crm_more_tab.dart';

/// 🏢 PANEL ORGANIZACIONAL (U07 BUSINESS / CRM B15)
/// Host screen that contains the 5 bottom tabs for the CRM.
class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const CrmResumeTab(),
    const Center(child: Text('Propiedades (En construcción)', style: TextStyle(color: KazaTheme.textPrimary))),
    const CrmPipelineTab(),
    const CrmActivityTab(),
    const CrmMoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: KazaTheme.azulKaza),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.business_rounded, color: KazaTheme.coralKaza, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Business',
              style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: KazaTheme.coralKaza.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: const Text('Admin', style: TextStyle(color: KazaTheme.coralKaza, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: KazaTheme.azulKaza),
            onPressed: () {}, // Ajustes de la org
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: KazaTheme.primaryCoral,
          unselectedItemColor: KazaTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.maps_home_work_outlined), activeIcon: Icon(Icons.maps_home_work_rounded), label: 'Propiedades'),
            BottomNavigationBarItem(icon: Icon(Icons.view_kanban_outlined), activeIcon: Icon(Icons.view_kanban_rounded), label: 'CRM'),
            BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), activeIcon: Icon(Icons.timeline_rounded), label: 'Actividad'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), activeIcon: Icon(Icons.grid_view_rounded), label: 'Más'),
          ],
        ),
      ),
    );
  }
}
