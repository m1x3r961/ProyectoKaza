import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock states
  bool pushMensajes = true;
  bool pushVisitas = true;
  bool pushIntereses = false;
  bool pushActividad = true;
  bool pushColaboraciones = true;
  
  bool emailResumen = false;
  bool emailNovedades = true;
  bool emailConsejos = false;
  
  bool marketing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Notificaciones', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('Push'),
          _buildSwitch('Mensajes', pushMensajes, (val) => setState(() => pushMensajes = val)),
          _buildSwitch('Visitas y contactos', pushVisitas, (val) => setState(() => pushVisitas = val)),
          _buildSwitch('Intereses en mis propiedades', pushIntereses, (val) => setState(() => pushIntereses = val)),
          _buildSwitch('Publicaciones y actividad', pushActividad, (val) => setState(() => pushActividad = val)),
          _buildSwitch('Colaboraciones', pushColaboraciones, (val) => setState(() => pushColaboraciones = val)),
          
          const SizedBox(height: 32),
          _buildSectionTitle('Email'),
          _buildSwitch('Resumen diario', emailResumen, (val) => setState(() => emailResumen = val)),
          _buildSwitch('Novedades de KAZA', emailNovedades, (val) => setState(() => emailNovedades = val)),
          _buildSwitch('Consejos y actualizaciones', emailConsejos, (val) => setState(() => emailConsejos = val)),
          
          const SizedBox(height: 32),
          _buildSwitch('Notificaciones de marketing', marketing, (val) => setState(() => marketing = val), isBold: true),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary)),
    );
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title, 
              style: TextStyle(
                fontSize: 15, 
                color: KazaTheme.textPrimary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: KazaTheme.textPrimary, // Almost black like in the mock
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: KazaTheme.glassBorder,
          ),
        ],
      ),
    );
  }
}
