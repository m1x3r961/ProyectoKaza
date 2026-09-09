import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/crm_models.dart';

class CrmScheduleVisitScreen extends ConsumerStatefulWidget {
  final CrmOpportunity opportunity;

  const CrmScheduleVisitScreen({super.key, required this.opportunity});

  @override
  ConsumerState<CrmScheduleVisitScreen> createState() => _CrmScheduleVisitScreenState();
}

class _CrmScheduleVisitScreenState extends ConsumerState<CrmScheduleVisitScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  void _schedule() {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona fecha y hora.')));
      return;
    }
    
    // Aquí iría el guardado en visit_records.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visita agendada con éxito.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Agendar Visita', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: KazaTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Agendar visita para: ${widget.opportunity.title}', style: const TextStyle(fontSize: 16, color: KazaTheme.textSecondary)),
            const SizedBox(height: 32),
            
            const Text('Fecha', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: KazaTheme.grisClaro,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.calendar_today, color: KazaTheme.azulKaza),
              title: Text(_selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' : 'Seleccionar fecha'),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 24),
            
            const Text('Hora', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KazaTheme.textPrimary)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: KazaTheme.grisClaro,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.access_time, color: KazaTheme.azulKaza),
              title: Text(_selectedTime != null ? _selectedTime!.format(context) : 'Seleccionar hora'),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null) setState(() => _selectedTime = time);
              },
            ),
            const SizedBox(height: 48),
            
            ElevatedButton(
              onPressed: _schedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar Cita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
