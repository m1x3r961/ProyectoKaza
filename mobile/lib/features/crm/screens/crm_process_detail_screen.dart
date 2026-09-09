import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/crm_models.dart';
import 'crm_opportunities_screen.dart';
import 'crm_schedule_visit_screen.dart';
import 'crm_negotiation_screen.dart';
import 'crm_close_operation_screen.dart';

class CrmProcessDetailScreen extends ConsumerStatefulWidget {
  final CrmOpportunity opportunity;

  const CrmProcessDetailScreen({super.key, required this.opportunity});

  @override
  ConsumerState<CrmProcessDetailScreen> createState() => _CrmProcessDetailScreenState();
}

class _CrmProcessDetailScreenState extends ConsumerState<CrmProcessDetailScreen> {
  late CrmOpportunity _opp;
  
  final List<String> _stages = ['INTERESADO', 'CONTACTO', 'VISITA', 'NEGOCIACION', 'CERRADA'];

  @override
  void initState() {
    super.initState();
    _opp = widget.opportunity;
  }

  void _updateStage(String newStage) async {
    // Aquí se llamaría al provider para actualizar en DB
    // await ref.read(crmProvider.notifier).updateStage(_opp.id, newStage);
    setState(() {
      // Mock update for now
      _opp = CrmOpportunity(
        id: _opp.id,
        title: _opp.title,
        stage: newStage,
        amountExpected: _opp.amountExpected,
        contactId: _opp.contactId,
        contact: _opp.contact,
        interestLevel: _opp.interestLevel,
        leadSource: _opp.leadSource,
        rejectionReason: _opp.rejectionReason,
      );
    });
    // Trigger refresh on the list
    ref.invalidate(crmOpportunitiesProvider); // from crm_opportunities_screen.dart
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: List.generate(_stages.length, (index) {
          final stage = _stages[index];
          final currentIndex = _stages.indexOf(_opp.stage);
          // If stage is DESCARTADO, it won't match any index, so currentIndex is -1.
          final isCompleted = currentIndex >= index && _opp.stage != 'DESCARTADO';
          final isCurrent = currentIndex == index && _opp.stage != 'DESCARTADO';
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? KazaTheme.azulKaza : KazaTheme.grisClaro,
                          border: isCurrent ? Border.all(color: KazaTheme.azulKaza.withOpacity(0.3), width: 4) : null,
                        ),
                        child: isCompleted && !isCurrent
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stage,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? KazaTheme.textPrimary : KazaTheme.textMuted,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < _stages.length - 1)
                  Expanded(
                    child: Divider(
                      color: isCompleted ? KazaTheme.azulKaza : KazaTheme.grisClaro,
                      thickness: 2,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    if (_opp.stage == 'DESCARTADO') {
      return [
        ElevatedButton(
          onPressed: () => _updateStage('INTERESADO'),
          style: ElevatedButton.styleFrom(backgroundColor: KazaTheme.azulKaza, foregroundColor: Colors.white),
          child: const Text('Reabrir Proceso'),
        ),
      ];
    }

    final actions = <Widget>[];

    if (_opp.stage == 'INTERESADO') {
      actions.add(ElevatedButton(
        onPressed: () => _updateStage('CONTACTO'),
        style: ElevatedButton.styleFrom(backgroundColor: KazaTheme.azulKaza, foregroundColor: Colors.white),
        child: const Text('Avanzar a Contacto'),
      ));
    } else if (_opp.stage == 'CONTACTO') {
      actions.add(ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CrmScheduleVisitScreen(opportunity: _opp))),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: KazaTheme.azulKaza, side: const BorderSide(color: KazaTheme.azulKaza)),
        child: const Text('Agendar Visita'),
      ));
      actions.add(const SizedBox(height: 8));
      actions.add(ElevatedButton(
        onPressed: () => _updateStage('VISITA'),
        style: ElevatedButton.styleFrom(backgroundColor: KazaTheme.azulKaza, foregroundColor: Colors.white),
        child: const Text('Ya se realizó visita'),
      ));
    } else if (_opp.stage == 'VISITA') {
      actions.add(ElevatedButton(
        onPressed: () => _updateStage('NEGOCIACION'),
        style: ElevatedButton.styleFrom(backgroundColor: KazaTheme.azulKaza, foregroundColor: Colors.white),
        child: const Text('Iniciar Negociación'),
      ));
    } else if (_opp.stage == 'NEGOCIACION') {
      actions.add(ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CrmNegotiationScreen(opportunity: _opp))),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: KazaTheme.azulKaza, side: const BorderSide(color: KazaTheme.azulKaza)),
        child: const Text('Actualizar Oferta'),
      ));
      actions.add(const SizedBox(height: 8));
      actions.add(ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CrmCloseOperationScreen(opportunity: _opp))),
        style: ElevatedButton.styleFrom(backgroundColor: KazaTheme.verifiedGreen, foregroundColor: Colors.white),
        child: const Text('Cerrar Operación'),
      ));
    }

    if (_opp.stage != 'CERRADA') {
      actions.add(const SizedBox(height: 16));
      actions.add(TextButton(
        onPressed: () => _updateStage('DESCARTADO'),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        child: const Text('Descartar Proceso'),
      ));
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.n000,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detalle del Proceso', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: KazaTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepper(),
            const Divider(height: 1, color: KazaTheme.glassBorder),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_opp.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
                  const SizedBox(height: 24),
                  
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KazaTheme.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Información del Interesado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        _InfoRow(icon: Icons.person, label: 'Nombre', value: '${_opp.contact?.firstName ?? 'N/A'} ${_opp.contact?.lastName ?? ''}'.trim()),
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.phone, label: 'Teléfono', value: _opp.contact?.phone ?? 'N/A'),
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.email, label: 'Correo', value: _opp.contact?.email ?? 'N/A'),
                        const Divider(height: 24),
                        _InfoRow(icon: Icons.source, label: 'Origen', value: _opp.leadSource ?? 'Desconocido'),
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.local_fire_department, label: 'Nivel de Interés', value: _opp.interestLevel),
                        if (_opp.amountExpected > 0) ...[
                          const SizedBox(height: 8),
                          _InfoRow(icon: Icons.attach_money, label: 'Oferta Actual', value: 'USD ${_opp.amountExpected.toInt()}', valueColor: KazaTheme.verifiedGreen),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Acciones
                  const Text('Acciones Disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textSecondary)),
                  const SizedBox(height: 16),
                  ..._buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: KazaTheme.textMuted),
        const SizedBox(width: 8),
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14))),
        Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? KazaTheme.textPrimary))),
      ],
    );
  }
}
