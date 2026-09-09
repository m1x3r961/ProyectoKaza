import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/crm_models.dart';

class CrmNegotiationScreen extends ConsumerStatefulWidget {
  final CrmOpportunity opportunity;

  const CrmNegotiationScreen({super.key, required this.opportunity});

  @override
  ConsumerState<CrmNegotiationScreen> createState() => _CrmNegotiationScreenState();
}

class _CrmNegotiationScreenState extends ConsumerState<CrmNegotiationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.opportunity.amountExpected > 0 ? widget.opportunity.amountExpected.toInt().toString() : '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveOffer() {
    if (!_formKey.currentState!.validate()) return;
    
    // Aquí iría el guardado en base de datos.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta actualizada y guardada con éxito.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Negociar / Proponer', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: KazaTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Actualizar oferta para: ${widget.opportunity.title}', style: const TextStyle(fontSize: 16, color: KazaTheme.textSecondary)),
              const SizedBox(height: 32),
              
              const Text('Monto de la Oferta (USD)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej. 150000',
                  filled: true,
                  fillColor: KazaTheme.grisClaro,
                  prefixIcon: const Icon(Icons.attach_money, color: KazaTheme.azulKaza),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              
              const Text('Condiciones / Notas Adicionales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ej. El comprador solicita incluir los muebles de la sala.',
                  filled: true,
                  fillColor: KazaTheme.grisClaro,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _saveOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KazaTheme.azulKaza,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Guardar Propuesta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
