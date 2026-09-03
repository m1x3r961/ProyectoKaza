import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _theme = 'Claro'; // Claro, Oscuro, Automático
  double _radius = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Preferencias', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildOptionRow('Moneda', 'USD - Dólar americano'),
          const SizedBox(height: 24),
          _buildOptionRow('Unidades de medida', 'm², km, °C'),
          const SizedBox(height: 24),
          _buildOptionRow('Idioma', 'Español'),
          
          const SizedBox(height: 32),
          const Text('Tema de la app', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildThemeOption('Claro')),
              const SizedBox(width: 8),
              Expanded(child: _buildThemeOption('Oscuro')),
              const SizedBox(width: 8),
              Expanded(child: _buildThemeOption('Automático')),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildOptionRow('Región de búsqueda', 'Santa Cruz, Bolivia'),
          
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Radio de búsqueda predeterminado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: KazaTheme.textPrimary)),
              Text('${_radius.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: KazaTheme.textPrimary,
              inactiveTrackColor: KazaTheme.glassBorder,
              thumbColor: KazaTheme.textPrimary,
              overlayColor: KazaTheme.textPrimary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _radius,
              min: 5,
              max: 100,
              divisions: 95,
              onChanged: (val) => setState(() => _radius = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('5 km', style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
              Text('100 km', style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOptionRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, color: KazaTheme.textPrimary)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontSize: 14, color: KazaTheme.textSecondary)),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more, color: KazaTheme.textSecondary, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(String title) {
    final isSelected = _theme == title;
    return GestureDetector(
      onTap: () => setState(() => _theme = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? KazaTheme.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? KazaTheme.textPrimary : KazaTheme.glassBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : KazaTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
