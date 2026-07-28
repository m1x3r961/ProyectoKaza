import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../providers/map_properties_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../saved/screens/saved_screen.dart';

/// 🏠 PROPERTY DETAIL SCREEN - Detalle completo de la propiedad, Plano 2D y Visor 3D 360°
class PropertyDetailScreen extends ConsumerStatefulWidget {
  final PropertyMapItem property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRoomIndex = 0;

  // 3D Orbital Controls State
  double _rotationY = 0.6;
  double _rotationX = 0.3;
  double _zoomScale = 1.0;
  bool _showWireframe3D = false;
  int _activeFloor = 1;

  final List<Map<String, dynamic>> _rooms = [
    {
      'name': 'Living & Comedor',
      'surface': '32.5 m²',
      'dimensions': '6.5m x 5.0m',
      'icon': Icons.living,
      'color': KazaTheme.primaryCoral,
      'rect': const Rect.fromLTWH(20, 20, 160, 120),
    },
    {
      'name': 'Dormitorio Master',
      'surface': '21.0 m²',
      'dimensions': '4.5m x 4.6m',
      'icon': Icons.king_bed,
      'color': KazaTheme.accentGold,
      'rect': const Rect.fromLTWH(190, 20, 130, 100),
    },
    {
      'name': 'Cocina Gourmet',
      'surface': '14.2 m²',
      'dimensions': '4.0m x 3.5m',
      'icon': Icons.kitchen,
      'color': Color(0xFF10B981),
      'rect': const Rect.fromLTWH(20, 150, 110, 90),
    },
    {
      'name': 'Balcón & Terraza',
      'surface': '12.0 m²',
      'dimensions': '6.0m x 2.0m',
      'icon': Icons.deck,
      'color': Color(0xFF3B82F6),
      'rect': const Rect.fromLTWH(140, 150, 180, 50),
    },
    {
      'name': 'Baño Principal',
      'surface': '5.8 m²',
      'dimensions': '2.9m x 2.0m',
      'icon': Icons.bathtub,
      'color': Color(0xFF8B5CF6),
      'rect': const Rect.fromLTWH(140, 210, 80, 60),
    },
  ];

  final List<Map<String, dynamic>> _amenities = [
    {'name': 'Piscina Infinity', 'icon': Icons.pool},
    {'name': 'Churrasquero BBQ', 'icon': Icons.outdoor_grill},
    {'name': 'Seguridad 24/7 Biométrica', 'icon': Icons.security},
    {'name': 'Garaje Subterráneo', 'icon': Icons.directions_car},
    {'name': 'Gimnasio Equipado', 'icon': Icons.fitness_center},
    {'name': 'Aire Acondicionado Central', 'icon': Icons.ac_unit},
    {'name': 'Balcón Panorámico', 'icon': Icons.balcony},
    {'name': 'Pet Friendly', 'icon': Icons.pets},
    {'name': 'Ascensor Inteligente', 'icon': Icons.elevator},
    {'name': 'Sistema Domótico IoT', 'icon': Icons.home_max},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.darkBackground,
      appBar: AppBar(
        title: Text(widget.property.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: KazaTheme.accentGold),
            onPressed: () async {
              try {
                final userId = SupabaseConfig.client.auth.currentUser?.id;
                final payload = {'property_id': widget.property.id};
                if (userId != null) payload['user_id'] = userId;

                await SupabaseConfig.client.from('saved_properties').insert(payload);
                
                ref.invalidate(savedPropertiesProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⭐ Propiedad guardada en tu lista de favoritos'),
                    backgroundColor: KazaTheme.primaryCoral,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar (¿ya está guardada?): $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔗 Enlace copiado al portapapeles')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KazaTheme.primaryCoralLight,
          labelColor: KazaTheme.primaryCoralLight,
          unselectedLabelColor: KazaTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'OFERTA & DETALLE'),
            Tab(icon: Icon(Icons.architecture), text: 'PLANO 2D'),
            Tab(icon: Icon(Icons.view_in_ar), text: 'VISOR 3D 360°'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Características & Ofertas de la propiedad
          _buildOverviewTab(),

          // Tab 2: Plano 2D Interactivo con cotas y áreas
          _buildFloorPlan2DTab(),

          // Tab 3: Visor 3D & Recorrido Virtual Interactivo
          _buildVirtualTour3DTab(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: KazaTheme.cardSurface,
          border: Border(top: BorderSide(color: KazaTheme.glassBorder)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Precio Final', style: TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
                Text(
                  widget.property.price,
                  style: const TextStyle(
                    color: KazaTheme.primaryCoralLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KazaTheme.primaryCoral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat),
                label: const Text('Contactar / Agendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('💬 Iniciando chat seguro con el agente certificado...'),
                      backgroundColor: KazaTheme.primaryCoral,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Oferta, Características y Amenidades
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Gallery Header Simulation
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                color: Colors.grey.shade900,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo.png', height: 60),
                      const SizedBox(height: 8),
                      const Text(
                        'Galería Fotográfica Verificada (HD)',
                        style: TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    if (widget.property.isPlus) const KazaPlusBadge(),
                    const SizedBox(width: 8),
                    KazaTrustBadge(
                      label: widget.property.trustLabel,
                      isOrganization: widget.property.isOrg,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('1 / 12 Fotos', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Title & Price Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.property.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: KazaTheme.primaryCoralLight),
                      const SizedBox(width: 4),
                      Text(
                        'Equipetrol / Sirari, Santa Cruz, Bolivia',
                        style: const TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: KazaTheme.primaryCoral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KazaTheme.primaryCoralLight),
              ),
              child: Text(
                widget.property.operation,
                style: const TextStyle(color: KazaTheme.primaryCoralLight, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Quick Specs Cards Row
        Row(
          children: [
            _buildSpecChip(Icons.king_bed_outlined, '${widget.property.bedrooms} Dormitorios'),
            const SizedBox(width: 8),
            _buildSpecChip(Icons.bathtub_outlined, '${widget.property.bathrooms} Baños'),
            const SizedBox(width: 8),
            _buildSpecChip(Icons.square_foot, widget.property.surface),
            const SizedBox(width: 8),
            _buildSpecChip(Icons.directions_car_outlined, '1 Garaje'),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(color: KazaTheme.glassBorder),
        const SizedBox(height: 16),

        // SECTION: Lo que ofrece esta propiedad
        Row(
          children: [
            const Icon(Icons.verified_outlined, color: KazaTheme.accentGold, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Lo que ofrece esta propiedad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _amenities.length,
          itemBuilder: (context, idx) {
            final item = _amenities[idx];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: KazaTheme.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: KazaTheme.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, size: 18, color: KazaTheme.primaryCoralLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),
        const Divider(color: KazaTheme.glassBorder),
        const SizedBox(height: 16),

        // SECTION: Descripción
        const Text('Descripción del Inmueble', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Exclusivo inmueble ubicado en la zona de mayor plusvalía de Santa Cruz. Cuenta con acabados de primera calidad, pisos de porcelanato italiano importado, mesones de granito en cocina y baños, suite principal con vestidor amplio y balcón privado con orientación privilegiada.\n\n'
          'Edificio de categoría premium con lobby de doble altura, seguridad física 24/7 con control biométrico, 2 ascensores de alta velocidad y terraza social panorámica.',
          style: TextStyle(color: KazaTheme.textSecondary, height: 1.5, fontSize: 13),
        ),

        const SizedBox(height: 24),
        const Divider(color: KazaTheme.glassBorder),
        const SizedBox(height: 16),

        // SECTION: Vendedor / Agente Certificado
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: KazaTheme.primaryCoral,
                  child: const Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inmobiliaria Kaza Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      const Text('Empresa Verificada por Kaza Guard', style: TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
                      const SizedBox(height: 6),
                      KazaTrustBadge(label: widget.property.trustLabel, isOrganization: widget.property.isOrg),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: KazaTheme.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KazaTheme.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: KazaTheme.primaryCoralLight),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Plano 2D Interactivo con Cotas
  // ---------------------------------------------------------------------------
  Widget _buildFloorPlan2DTab() {
    final selectedRoom = _rooms[_selectedRoomIndex];

    return Column(
      children: [
        // Room Selector Header Chips
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: KazaTheme.cardSurface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_rooms.length, (idx) {
                final r = _rooms[idx];
                final isSel = idx == _selectedRoomIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    avatar: Icon(r['icon'] as IconData, size: 16, color: isSel ? Colors.white : KazaTheme.primaryCoralLight),
                    label: Text(r['name'] as String),
                    selected: isSel,
                    selectedColor: KazaTheme.primaryCoral,
                    backgroundColor: KazaTheme.darkBackground,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : KazaTheme.textPrimary,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedRoomIndex = idx);
                    },
                  ),
                );
              }),
            ),
          ),
        ),

        // Floorplan Canvas Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F141F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KazaTheme.glassBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Blueprint Grid & Custom Painter
                  CustomPaint(
                    size: Size.infinite,
                    painter: FloorPlan2DPainter(
                      rooms: _rooms,
                      selectedIndex: _selectedRoomIndex,
                    ),
                  ),

                  // Room Info Floating Overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KazaTheme.cardSurface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KazaTheme.primaryCoralLight),
                      ),
                      child: Row(
                        children: [
                          Icon(selectedRoom['icon'] as IconData, color: selectedRoom['color'] as Color, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedRoom['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Dimensiones: ${selectedRoom['dimensions']} · Área: ${selectedRoom['surface']}',
                                  style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (selectedRoom['color'] as Color).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedRoom['surface'] as String,
                              style: TextStyle(
                                color: selectedRoom['color'] as Color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Visor 3D & Recorrido Virtual Interactivo
  // ---------------------------------------------------------------------------
  Widget _buildVirtualTour3DTab() {
    return Column(
      children: [
        // 3D Controls Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: KazaTheme.cardSurface,
          child: Row(
            children: [
              const Icon(Icons.threed_rotation, color: KazaTheme.accentGold, size: 20),
              const SizedBox(width: 8),
              const Text('Visor Espacial 3D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),

              // Floor Level Switcher
              DropdownButton<int>(
                value: _activeFloor,
                dropdownColor: KazaTheme.cardSurface,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Nivel 1', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 2, child: Text('Nivel 2 (Terraza)', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _activeFloor = val);
                },
              ),
              const SizedBox(width: 8),

              // Wireframe Toggle Button
              IconButton(
                icon: Icon(
                  _showWireframe3D ? Icons.grid_4x4 : Icons.view_in_ar,
                  color: _showWireframe3D ? KazaTheme.accentGold : Colors.white,
                ),
                tooltip: 'Modo Estructura 3D',
                onPressed: () {
                  setState(() => _showWireframe3D = !_showWireframe3D);
                },
              ),
            ],
          ),
        ),

        // Interactive 3D Canvas
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0D14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KazaTheme.glassBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rotationY += details.delta.dx * 0.01;
                    _rotationX += details.delta.dy * 0.01;
                    // Clamp pitch angle
                    _rotationX = _rotationX.clamp(-1.0, 1.0);
                  });
                },
                child: Stack(
                  children: [
                    // 3D Custom Painter (Orbital Projection)
                    CustomPaint(
                      size: Size.infinite,
                      painter: VirtualModel3DPainter(
                        rotationY: _rotationY,
                        rotationX: _rotationX,
                        zoom: _zoomScale,
                        isWireframe: _showWireframe3D,
                        floor: _activeFloor,
                      ),
                    ),

                    // Touch Instructions Overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app, size: 14, color: KazaTheme.accentGold),
                            SizedBox(width: 6),
                            Text('Arrastra para orbitar en 360°', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),

                    // Zoom In/Out Buttons
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoom_in_3d',
                            backgroundColor: KazaTheme.cardSurface,
                            child: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              setState(() => _zoomScale = (_zoomScale * 1.2).clamp(0.5, 3.0));
                            },
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoom_out_3d',
                            backgroundColor: KazaTheme.cardSurface,
                            child: const Icon(Icons.remove, color: Colors.white),
                            onPressed: () {
                              setState(() => _zoomScale = (_zoomScale / 1.2).clamp(0.5, 3.0));
                            },
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'reset_3d',
                            backgroundColor: KazaTheme.cardSurface,
                            child: const Icon(Icons.restart_alt, color: KazaTheme.accentGold),
                            onPressed: () {
                              setState(() {
                                _rotationY = 0.6;
                                _rotationX = 0.3;
                                _zoomScale = 1.0;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CUSTOM PAINTER 1: Plano 2D Interactivo con Cotas y Blueprint Grid
// =============================================================================
class FloorPlan2DPainter extends CustomPainter {
  final List<Map<String, dynamic>> rooms;
  final int selectedIndex;

  FloorPlan2DPainter({required this.rooms, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid Background (Blueprint Style)
    final gridPaint = Paint()
      ..color = const Color(0x153B82F6)
      ..strokeWidth = 1;

    const double step = 25.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Rooms
    final borderPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final selectedBorderPaint = Paint()
      ..color = KazaTheme.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    for (int i = 0; i < rooms.length; i++) {
      final r = rooms[i];
      final Rect rawRect = r['rect'] as Rect;
      final Color roomColor = r['color'] as Color;
      final bool isSel = i == selectedIndex;

      // Scale rect to canvas size
      final scaledRect = Rect.fromLTWH(
        rawRect.left * (size.width / 340),
        rawRect.top * (size.height / 320),
        rawRect.width * (size.width / 340),
        rawRect.height * (size.height / 320),
      );

      // Room Fill
      final fillPaint = Paint()
        ..color = roomColor.withValues(alpha: isSel ? 0.35 : 0.15)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), fillPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), isSel ? selectedBorderPaint : borderPaint);

      // Room Title Text
      final textSpan = TextSpan(
        text: '${r['name']}\n${r['surface']}',
        style: TextStyle(
          color: isSel ? KazaTheme.accentGold : Colors.white,
          fontSize: isSel ? 12 : 10,
          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: scaledRect.width);
      textPainter.paint(
        canvas,
        Offset(
          scaledRect.center.dx - (textPainter.width / 2),
          scaledRect.center.dy - (textPainter.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FloorPlan2DPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex;
}

// =============================================================================
// CUSTOM PAINTER 2: Visor Tridimensional 3D con Proyección Orbital
// =============================================================================
class VirtualModel3DPainter extends CustomPainter {
  final double rotationY;
  final double rotationX;
  final double zoom;
  final bool isWireframe;
  final int floor;

  VirtualModel3DPainter({
    required this.rotationY,
    required this.rotationX,
    required this.zoom,
    required this.isWireframe,
    required this.floor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);

    // 3D Bounding Box Vertices for Floor Model
    final List<List<double>> rawVertices = [
      // Base
      [-100, 60, -80],
      [100, 60, -80],
      [100, 60, 80],
      [-100, 60, 80],
      // Roof / Ceiling Level 1
      [-100, -20, -80],
      [100, -20, -80],
      [100, -20, 80],
      [-100, -20, 80],
    ];

    if (floor == 2) {
      // Add Level 2 structure
      rawVertices.addAll([
        [-60, -90, -50],
        [60, -90, -50],
        [60, -90, 50],
        [-60, -90, 50],
      ]);
    }

    // 3D Orbital Projection Math
    final projected = rawVertices.map((v) {
      double x = v[0] * zoom;
      double y = v[1] * zoom;
      double z = v[2] * zoom;

      // Rotate Y (Yaw)
      double radY = rotationY;
      double x1 = x * math.cos(radY) + z * math.sin(radY);
      double z1 = -x * math.sin(radY) + z * math.cos(radY);

      // Rotate X (Pitch)
      double radX = rotationX;
      double y2 = y * math.cos(radX) - z1 * math.sin(radX);

      return Offset(center.dx + x1, center.dy + y2);
    }).toList();

    // 3D Edges
    final List<List<int>> edges = [
      [0, 1], [1, 2], [2, 3], [3, 0], // Base
      [4, 5], [5, 6], [6, 7], [7, 4], // Ceiling Level 1
      [0, 4], [1, 5], [2, 6], [3, 7], // Columns
    ];

    if (floor == 2 && projected.length >= 12) {
      edges.addAll([
        [8, 9], [9, 10], [10, 11], [11, 8], // Level 2 Roof
        [4, 8], [5, 9], [6, 10], [7, 11],
      ]);
    }

    final edgePaint = Paint()
      ..color = isWireframe ? KazaTheme.accentGold : KazaTheme.primaryCoralLight
      ..strokeWidth = isWireframe ? 1.5 : 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = KazaTheme.primaryCoral.withValues(alpha: isWireframe ? 0.05 : 0.25)
      ..style = PaintingStyle.fill;

    // Draw Solid Faces if not wireframe mode
    if (!isWireframe) {
      final Path wallPath = Path()
        ..moveTo(projected[0].dx, projected[0].dy)
        ..lineTo(projected[1].dx, projected[1].dy)
        ..lineTo(projected[5].dx, projected[5].dy)
        ..lineTo(projected[4].dx, projected[4].dy)
        ..close();

      final Path roofPath = Path()
        ..moveTo(projected[4].dx, projected[4].dy)
        ..lineTo(projected[5].dx, projected[5].dy)
        ..lineTo(projected[6].dx, projected[6].dy)
        ..lineTo(projected[7].dx, projected[7].dy)
        ..close();

      canvas.drawPath(wallPath, fillPaint);
      canvas.drawPath(roofPath, fillPaint);
    }

    // Draw Wireframe Edges
    for (final edge in edges) {
      canvas.drawLine(projected[edge[0]], projected[edge[1]], edgePaint);
    }

    // Draw Nodes / Vertices
    final nodePaint = Paint()..color = KazaTheme.accentGold;
    for (final pt in projected) {
      canvas.drawCircle(pt, 3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VirtualModel3DPainter oldDelegate) => true;
}
