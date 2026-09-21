import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/fintech_models.dart';
import '../services/fintech_api_service.dart';

class CreditSimulatorSheet extends StatefulWidget {
  final FintechApiService apiService;

  const CreditSimulatorSheet({
    super.key,
    required this.apiService,
  });

  @override
  State<CreditSimulatorSheet> createState() => _CreditSimulatorSheetState();
}

class _CreditSimulatorSheetState extends State<CreditSimulatorSheet> {
  final _incomeController = TextEditingController(text: '8000');
  final _expensesController = TextEditingController(text: '2000');
  final _ageController = TextEditingController(text: '35');
  final _amountController = TextEditingController(text: '350000');
  
  double _termYears = 20.0;
  bool _isLoading = false;
  CreditResult? _result;

  Future<void> _simulate() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    // Simular tiempo del IA procesando
    await Future.delayed(const Duration(seconds: 3));

    final income = double.tryParse(_incomeController.text) ?? 0;
    final expenses = double.tryParse(_expensesController.text) ?? 0;
    final age = int.tryParse(_ageController.text) ?? 30;
    final amount = double.tryParse(_amountController.text) ?? 0;

    final result = await widget.apiService.evaluateCredit(
      monthlyIncome: income,
      monthlyExpenses: expenses,
      applicantAge: age,
      requestedAmount: amount,
      termYears: _termYears.toInt(),
    );

    setState(() {
      _isLoading = false;
      _result = result;
    });
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
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KazaTheme.coralKaza.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_graph_rounded, color: KazaTheme.coralKaza),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'IA Scoring Crediticio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Kaza utiliza Inteligencia Artificial para pre-calificarte al instante usando el motor simulado del Banco Unión.',
            style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: _result != null ? _buildResult() : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ingreso mensual (Bs)', prefixIcon: Icon(Icons.attach_money)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _expensesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Gastos fijos (Bs)', prefixIcon: Icon(Icons.money_off)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tu edad', prefixIcon: Icon(Icons.cake_outlined)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto préstamo (Bs)', prefixIcon: Icon(Icons.home_work_outlined)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Plazo del crédito: ${_termYears.toInt()} años', style: const TextStyle(fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
        Slider(
          value: _termYears,
          min: 5,
          max: 30,
          divisions: 25,
          activeColor: KazaTheme.coralKaza,
          label: '${_termYears.toInt()} años',
          onChanged: (val) => setState(() => _termYears = val),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _simulate,
            style: ElevatedButton.styleFrom(
              backgroundColor: KazaTheme.coralKaza,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 12),
                      Text('IA Procesando Riesgo...'),
                    ],
                  )
                : const Text('Generar Scoring Pre-Aprobatorio'),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final bool isApproved = _result!.success;
    final formatter = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isApproved ? KazaTheme.semanticSuccess.withValues(alpha: 0.1) : KazaTheme.semanticError.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isApproved ? KazaTheme.semanticSuccess.withValues(alpha: 0.3) : KazaTheme.semanticError.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(
                isApproved ? Icons.celebration_rounded : Icons.warning_amber_rounded,
                color: isApproved ? KazaTheme.semanticSuccess : KazaTheme.semanticError,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _result!.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isApproved ? KazaTheme.semanticSuccess : KazaTheme.semanticError,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_result!.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  _result!.rejectionReason!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        if (isApproved) ...[
          const SizedBox(height: 24),
          const Text('DETALLES DEL CRÉDITO', style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          _buildDetailRow('Producto', _result!.bankProduct ?? ''),
          _buildDetailRow('Tasa Anual', _result!.annualRate ?? ''),
          _buildDetailRow('Plazo', '${_result!.termYears} años'),
          const Divider(),
          _buildDetailRow('Cuota Mensual Estimada', formatter.format(_result!.monthlyFee ?? 0), isHighlight: true),
        ],
        if (!isApproved && _result!.recommendations.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('RECOMENDACIONES DE LA IA', style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          ..._result!.recommendations.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: KazaTheme.semanticWarning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 13))),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => _result = null),
            child: const Text('Nueva Simulación'),
          ),
        )
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? KazaTheme.coralKaza : KazaTheme.textPrimary,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: isHighlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
