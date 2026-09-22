import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/kaza_theme.dart';
import '../../../providers/crm_projects_provider.dart';
import '../../../models/project_unit_model.dart';

class CrmAvailabilityMatrix extends ConsumerWidget {
  final String projectId;

  const CrmAvailabilityMatrix({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(projectUnitsProvider(projectId));

    return unitsAsync.when(
      data: (units) {
        if (units.isEmpty) {
          return const Center(child: Text('No hay unidades registradas en este proyecto.'));
        }

        // Agrupar por piso (floorNumber)
        final Map<int, List<ProjectUnitModel>> unitsByFloor = {};
        for (var unit in units) {
          unitsByFloor.putIfAbsent(unit.floorNumber, () => []).add(unit);
        }

        final floors = unitsByFloor.keys.toList()..sort((a, b) => b.compareTo(a)); // Pisos más altos arriba

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLegend(),
            const SizedBox(height: 16),
            ...floors.map((floor) => _buildFloorRow(context, floor, unitsByFloor[floor]!)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Disponible', Colors.green),
        _buildLegendItem('Reservada', Colors.amber),
        _buildLegendItem('Vendida', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildFloorRow(BuildContext context, int floor, List<ProjectUnitModel> floorUnits) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Text('Piso $floor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: floorUnits.map((u) => _buildUnitBox(context, u)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitBox(BuildContext context, ProjectUnitModel unit) {
    Color bgColor;
    switch (unit.status) {
      case 'DISPONIBLE':
        bgColor = Colors.green;
        break;
      case 'RESERVADA':
        bgColor = Colors.amber;
        break;
      case 'VENDIDA':
      case 'ENTREGADA':
        bgColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _showUnitDetails(context, unit),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Center(
          child: Text(
            unit.unitCode,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _showUnitDetails(BuildContext context, ProjectUnitModel unit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unidad ${unit.unitCode}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
            const SizedBox(height: 12),
            Text('Estado: ${unit.status}', style: const TextStyle(fontSize: 16)),
            Text('Tipología: ${unit.typology}', style: const TextStyle(fontSize: 16)),
            Text('Precio: \$${unit.priceUsd.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            if (unit.status == 'DISPONIBLE')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/financing'); // Integración Fintech / Reserva
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KazaTheme.coralKaza,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Simular y Reservar (Fintech)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
