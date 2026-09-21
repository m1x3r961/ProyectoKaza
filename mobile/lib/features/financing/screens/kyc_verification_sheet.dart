import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../services/fintech_api_service.dart';

class KycVerificationSheet extends StatefulWidget {
  final FintechApiService apiService;
  final VoidCallback onVerified;

  const KycVerificationSheet({
    super.key,
    required this.apiService,
    required this.onVerified,
  });

  @override
  State<KycVerificationSheet> createState() => _KycVerificationSheetState();
}

class _KycVerificationSheetState extends State<KycVerificationSheet> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _verify() async {
    if (_idController.text.isEmpty || _nameController.text.isEmpty) {
      setState(() => _errorMsg = 'Completa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    // Simular tiempo de validación con el banco para la demostración
    await Future.delayed(const Duration(seconds: 2));

    final result = await widget.apiService.verifyKyc(
      idNumber: _idController.text,
      fullName: _nameController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      widget.onVerified();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: KazaTheme.semanticSuccess,
        ),
      );
    } else {
      setState(() => _errorMsg = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: KazaTheme.azulKaza),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Validación ASFI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Por normativas de la ASFI, necesitamos validar tu identidad antes de que puedas realizar reservas inmobiliarias o solicitar créditos.',
            style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _idController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Carnet de Identidad (C.I.)',
              prefixIcon: Icon(Icons.badge_outlined),
              hintText: 'Ej. 8765432 (Impar = Aprobar Demo)',
            ),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KazaTheme.semanticError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: KazaTheme.semanticError, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMsg!, style: const TextStyle(color: KazaTheme.semanticError, fontSize: 13))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Validar Identidad'),
            ),
          ),
        ],
      ),
    );
  }
}
