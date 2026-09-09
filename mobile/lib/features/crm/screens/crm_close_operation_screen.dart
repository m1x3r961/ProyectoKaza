import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/crm_models.dart';

class CrmCloseOperationScreen extends ConsumerStatefulWidget {
  final CrmOpportunity opportunity;

  const CrmCloseOperationScreen({super.key, required this.opportunity});

  @override
  ConsumerState<CrmCloseOperationScreen> createState() => _CrmCloseOperationScreenState();
}

class _CrmCloseOperationScreenState extends ConsumerState<CrmCloseOperationScreen> {
  String _operationType = 'Venta';

  void _confirmClose() {
    // Aquí iría el guardado en base de datos.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operación cerrada con éxito. ¡Felicidades!')));
    context.pop(); // volver al detalle
    context.pop(); // volver al Kanban
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Cerrar Operación', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: KazaTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: KazaTheme.verifiedGreen),
            const SizedBox(height: 24),
            Text('Estás a punto de cerrar la operación para:\n${widget.opportunity.title}', 
              style: const TextStyle(fontSize: 16, color: KazaTheme.textPrimary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            const Text('Tipo de Operación', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Venta'),
                    value: 'Venta',
                    groupValue: _operationType,
                    onChanged: (val) => setState(() => _operationType = val!),
                    contentPadding: EdgeInsets.zero,
                    activeColor: KazaTheme.azulKaza,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Alquiler'),
                    value: 'Alquiler',
                    groupValue: _operationType,
                    onChanged: (val) => setState(() => _operationType = val!),
                    contentPadding: EdgeInsets.zero,
                    activeColor: KazaTheme.azulKaza,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: KazaTheme.verifiedGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: KazaTheme.verifiedGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Al confirmar, el proceso pasará a estado CERRADA y se registrará en las métricas finales.',
                      style: TextStyle(color: KazaTheme.verifiedGreen.withOpacity(0.8), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _confirmClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.verifiedGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar Cierre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
