import 'package:flutter/material.dart';
import '../../../../app/theme/kaza_theme.dart';

class CrmPipelineTab extends StatelessWidget {
  const CrmPipelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _pipelineStage(context, 'Nuevos', '62', 'USD 4.3M', KazaTheme.azulKaza, isExpanded: true),
              _pipelineStage(context, 'Contactados', '64', 'USD 2.3M', Colors.blue, isExpanded: false),
              _pipelineStage(context, 'Visitas programadas', '38', 'USD 3.1M', Colors.orange, isExpanded: false),
              _pipelineStage(context, 'Propuestas', '16', 'USD 1.5M', Colors.purple, isExpanded: false),
              _pipelineStage(context, 'Negociación', '12', 'USD 1.2M', Colors.amber, isExpanded: false),
              _pipelineStage(context, 'Cerrados (Ganados)', '8', 'USD 3.8M', Colors.green, isExpanded: false),
              _pipelineStage(context, 'Cerrados (Perdidos)', '0', 'USD 0M', Colors.grey, isExpanded: false),
            ],
          ),
        ),
        _buildAddLeadBtn(),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text('Pipeline', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Este mes', style: TextStyle(color: KazaTheme.textPrimary, fontSize: 13)),
                  Icon(Icons.keyboard_arrow_down, color: KazaTheme.textMuted, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Todos los equipos', style: TextStyle(color: KazaTheme.textPrimary, fontSize: 13)),
                  Icon(Icons.keyboard_arrow_down, color: KazaTheme.textMuted, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pipelineStage(BuildContext context, String title, String count, String amount, Color color, {required bool isExpanded}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            leading: Icon(Icons.circle, color: color, size: 12),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_upward, color: Colors.green, size: 12),
                const SizedBox(width: 4),
                Text('10%', style: const TextStyle(color: Colors.green, fontSize: 12)),
                const SizedBox(width: 12),
                Text(amount, style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
                const SizedBox(width: 8),
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: KazaTheme.textMuted),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _leadItem('María Fernández', 'Casa en Equipetrol Norte', 'USD 200,000'),
                  _leadItem('Carlos Méndez', 'Departamento Urubó Village', 'USD 260,000'),
                  _leadItem('Ana Melgar', 'Casa Pampa', 'USD 350,000'),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _leadItem(String name, String property, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 16, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(property, style: const TextStyle(color: KazaTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAddLeadBtn() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KazaTheme.primaryCoral,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {},
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add),
            SizedBox(width: 8),
            Text('Nuevo lead', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
