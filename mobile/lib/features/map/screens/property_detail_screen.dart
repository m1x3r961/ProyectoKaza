// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../providers/map_properties_provider.dart';
import '../../saved/screens/saved_screen.dart';
import '../widgets/property_detail_sections.dart';

/// 🏠 PROPERTY DETAIL SCREEN — Ficha Completa de Propiedad KAZA v2
/// Prototipo B16 · Ficha completa con 12 secciones
class PropertyDetailScreen extends ConsumerStatefulWidget {
  final PropertyMapItem property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;

  // Legacy 2D/3D state (for dedicated tab view if user requests it)
  int _selectedRoomIndex = 0;
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 220;
      if (show != _showStickyHeader) {
        setState(() => _showStickyHeader = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── SAVE PROPERTY ─────────────────────────────────────────────────────────
  Future<void> _saveProperty() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final payload = {'property_id': widget.property.id};
      if (userId != null) payload['user_id'] = userId;
      await SupabaseConfig.client.from('saved_properties').insert(payload);
      ref.invalidate(savedPropertiesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⭐ Propiedad guardada en favoritos'),
          backgroundColor: KazaTheme.primaryCoral,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Sticky AppBar ──────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: Colors.white,
              foregroundColor: KazaTheme.azulKaza,
              elevation: _showStickyHeader ? 2 : 0,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black12,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: AnimatedOpacity(
                opacity: _showStickyHeader ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.property.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KazaTheme.azulKaza,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      widget.property.price,
                      style: const TextStyle(
                        color: KazaTheme.primaryCoral,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bookmark_border_rounded, size: 22),
                  onPressed: _saveProperty,
                  tooltip: 'Guardar propiedad',
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 22),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🔗 Enlace copiado')),
                    );
                  },
                  tooltip: 'Compartir',
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 1,
                  color: _showStickyHeader ? const Color(0xFFE2E8F0) : Colors.transparent,
                ),
              ),
            ),

            // ── Page Header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: KazaTheme.azulKaza,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ficha completa de propiedad',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: KazaTheme.azulKaza,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Explora en detalle con transparencia, contexto y confianza.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: KazaTheme.textSecondary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Trust pillars horizontal scroll
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _trustPillar(Icons.verified_outlined, 'Datos oficiales\ny verificados'),
                          const SizedBox(width: 8),
                          _trustPillar(Icons.update_rounded, 'Actualizado\ny transparente'),
                          const SizedBox(width: 8),
                          _trustPillar(Icons.bar_chart_rounded, 'Cobertura y\nmetodología visibles'),
                          const SizedBox(width: 8),
                          _trustPillar(Icons.business_center_outlined, 'Sin sesgos\ncomerciales'),
                          const SizedBox(width: 8),
                          _trustPillar(Icons.lock_outlined, 'Privado y\nseguro'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 01 · Hero / Resumen ────────────────────────────────────────
            SliverToBoxAdapter(
              child: PropertyHeroSection(
                property: widget.property,
                onScrollToGallery: () {
                  _scrollController.animateTo(
                    500,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),

            // ── 02 · Galería de fotos ──────────────────────────────────────
            SliverToBoxAdapter(
              child: PropertyGallerySection(property: widget.property),
            ),

            // ── 03 · Detalles de la propiedad ─────────────────────────────
            SliverToBoxAdapter(
              child: PropertyDetailsSection(property: widget.property),
            ),

            // ── 03a · Financiamiento Disponible ────────────────────────────
            SliverToBoxAdapter(
              child: _buildFinancingBanner(context),
            ),

            // ── 03b · Plano 2D Interactivo ─────────────────────────────────
            SliverToBoxAdapter(
              child: _buildFloorPlanCard(),
            ),

            // ── 04 · Descripción y destacados ─────────────────────────────
            SliverToBoxAdapter(
              child: PropertyDescriptionSection(property: widget.property),
            ),

            // ── 05 · Amenidades y características ─────────────────────────
            SliverToBoxAdapter(
              child: PropertyAmenitiesSection(property: widget.property),
            ),

            // ── 06 · Disponibilidad y frescura ────────────────────────────
            const SliverToBoxAdapter(
              child: PropertyAvailabilitySection(),
            ),

            // ── 07 · Ubicación y entorno ───────────────────────────────────
            const SliverToBoxAdapter(
              child: PropertyLocationSection(),
            ),

            // ── 08 · Anunciante / Publicador ──────────────────────────────
            const SliverToBoxAdapter(
              child: PropertyAgentSection(),
            ),

            // ── 09 · Documentos y legales ─────────────────────────────────
            const SliverToBoxAdapter(
              child: PropertyDocumentsSection(),
            ),

            // ── 10 · Guardar, comparar y compartir ────────────────────────
            SliverToBoxAdapter(
              child: PropertySaveShareSection(
                property: widget.property,
                onSave: _saveProperty,
              ),
            ),

            // ── 11 · Contacto y visitas ────────────────────────────────────
            const SliverToBoxAdapter(
              child: PropertyContactSection(),
            ),

            // ── 12 · Reportar publicación ──────────────────────────────────
            const SliverToBoxAdapter(
              child: PropertyReportSection(),
            ),

            // ── Visor 3D (bonus — collapsible) ────────────────────────────
            SliverToBoxAdapter(
              child: _buildVirtualTourCard(),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),

        // ── Sticky Bottom CTA ──────────────────────────────────────────────
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Precio',
                    style: TextStyle(color: KazaTheme.textSecondary, fontSize: 11),
                  ),
                  Text(
                    widget.property.price,
                    style: const TextStyle(
                      color: KazaTheme.azulKaza,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KazaTheme.primaryCoral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text(
                    'Contactar anunciante',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('💬 Iniciando chat seguro con el anunciante...'),
                        backgroundColor: KazaTheme.primaryCoral,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TRUST PILLAR CHIP ──────────────────────────────────────────────────────
  Widget _trustPillar(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KazaTheme.azulKaza),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: KazaTheme.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  // ─── FINANCING BANNER ───────────────────────────────────────────────────────
  Widget _buildFinancingBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KazaTheme.azulKaza.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.azulKaza.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: KazaTheme.glassBorder)),
                child: const Icon(Icons.account_balance_outlined, color: KazaTheme.azulKaza, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Financiamiento disponible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                    Text('Conecta con entidades financieras', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.push('/financing');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: KazaTheme.azulKaza),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ver opciones de financiamiento', style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: KazaTheme.azulKaza, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PLANO 2D CARD ──────────────────────────────────────────────────────────
  Widget _buildFloorPlanCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: KazaTheme.azulKaza, shape: BoxShape.circle),
                  child: const Text('03b', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.architecture, size: 18, color: KazaTheme.azulKaza),
                const SizedBox(width: 6),
                const Text('Plano 2D Interactivo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
              ],
            ),
            const SizedBox(height: 14),

            // Room chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_rooms.length, (idx) {
                  final r = _rooms[idx];
                  final isSel = idx == _selectedRoomIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRoomIndex = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? KazaTheme.azulKaza : KazaTheme.grisClaro,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? KazaTheme.azulKaza : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(r['icon'] as IconData, size: 14, color: isSel ? Colors.white : KazaTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              r['name'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSel ? Colors.white : KazaTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // 2D Canvas
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 260),
                      painter: FloorPlan2DPainter(rooms: _rooms, selectedIndex: _selectedRoomIndex),
                    ),
                    // Room info overlay
                    Positioned(
                      bottom: 12, left: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Icon(_rooms[_selectedRoomIndex]['icon'] as IconData, color: _rooms[_selectedRoomIndex]['color'] as Color, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_rooms[_selectedRoomIndex]['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KazaTheme.azulKaza)),
                                  Text(
                                    '${_rooms[_selectedRoomIndex]['dimensions']} · ${_rooms[_selectedRoomIndex]['surface']}',
                                    style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (_rooms[_selectedRoomIndex]['color'] as Color).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _rooms[_selectedRoomIndex]['surface'] as String,
                                style: TextStyle(color: _rooms[_selectedRoomIndex]['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12),
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
          ],
        ),
      ),
    );
  }

  // ─── VISOR 3D CARD (Collapsible) ────────────────────────────────────────────
  Widget _buildVirtualTourCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: KazaTheme.azulKaza, shape: BoxShape.circle),
                  child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.view_in_ar_outlined, size: 18, color: KazaTheme.azulKaza),
                const SizedBox(width: 6),
                const Text('Visor 3D Interactivo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
                const Spacer(),
                // Floor level
                DropdownButton<int>(
                  value: _activeFloor,
                  dropdownColor: Colors.white,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, color: KazaTheme.azulKaza),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Nivel 1')),
                    DropdownMenuItem(value: 2, child: Text('Nivel 2')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _activeFloor = v); },
                ),
                IconButton(
                  icon: Icon(
                    _showWireframe3D ? Icons.grid_4x4 : Icons.view_in_ar,
                    size: 20,
                    color: _showWireframe3D ? KazaTheme.primaryCoral : KazaTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _showWireframe3D = !_showWireframe3D),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3D canvas
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 280,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _rotationY += d.delta.dx * 0.01;
                      _rotationX = (_rotationX + d.delta.dy * 0.01).clamp(-1.0, 1.0);
                    });
                  },
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFFE8ECEF)),
                      CustomPaint(
                        size: const Size(double.infinity, 280),
                        painter: VirtualModel3DPainter(
                          rotationY: _rotationY,
                          rotationX: _rotationX,
                          zoom: _zoomScale,
                          isWireframe: _showWireframe3D,
                          floor: _activeFloor,
                        ),
                      ),
                      // Instructions
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.touch_app, size: 13, color: KazaTheme.primaryCoral),
                              SizedBox(width: 5),
                              Text('Arrastra para orbitar en 360°', style: TextStyle(fontSize: 11, color: KazaTheme.textSecondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      // Zoom controls
                      Positioned(
                        right: 10, bottom: 10,
                        child: Column(
                          children: [
                            _zoomBtn(Icons.add, 'zi', () => setState(() => _zoomScale = (_zoomScale * 1.2).clamp(0.5, 3.0))),
                            const SizedBox(height: 6),
                            _zoomBtn(Icons.remove, 'zo', () => setState(() => _zoomScale = (_zoomScale / 1.2).clamp(0.5, 3.0))),
                            const SizedBox(height: 6),
                            _zoomBtn(Icons.restart_alt, 'zr', () => setState(() { _rotationY = 0.6; _rotationX = 0.3; _zoomScale = 1.0; })),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, String tag, VoidCallback onPressed) {
    return FloatingActionButton.small(
      heroTag: tag,
      backgroundColor: Colors.white,
      elevation: 2,
      onPressed: onPressed,
      child: Icon(icon, size: 18, color: KazaTheme.azulKaza),
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
    // Blueprint background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFF0F4F8));

    // Grid
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

    // Rooms
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final selectedBorderPaint = Paint()
      ..color = KazaTheme.primaryCoral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    for (int i = 0; i < rooms.length; i++) {
      final r = rooms[i];
      final Rect rawRect = r['rect'] as Rect;
      final Color roomColor = r['color'] as Color;
      final bool isSel = i == selectedIndex;

      final scaledRect = Rect.fromLTWH(
        rawRect.left * (size.width / 340),
        rawRect.top * (size.height / 320),
        rawRect.width * (size.width / 340),
        rawRect.height * (size.height / 320),
      );

      final fillPaint = Paint()
        ..color = roomColor.withValues(alpha: isSel ? 0.35 : 0.15)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), fillPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
          isSel ? selectedBorderPaint : borderPaint);

      final textSpan = TextSpan(
        text: '${r['name']}\n${r['surface']}',
        style: TextStyle(
          color: isSel ? KazaTheme.primaryCoral : KazaTheme.textPrimary,
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

    final List<List<double>> rawVertices = [
      [-100, 60, -80], [100, 60, -80], [100, 60, 80], [-100, 60, 80],
      [-100, -20, -80], [100, -20, -80], [100, -20, 80], [-100, -20, 80],
    ];

    if (floor == 2) {
      rawVertices.addAll([
        [-60, -90, -50], [60, -90, -50], [60, -90, 50], [-60, -90, 50],
      ]);
    }

    final projected = rawVertices.map((v) {
      double x = v[0] * zoom;
      double y = v[1] * zoom;
      double z = v[2] * zoom;

      double radY = rotationY;
      double x1 = x * math.cos(radY) + z * math.sin(radY);
      double z1 = -x * math.sin(radY) + z * math.cos(radY);

      double radX = rotationX;
      double y2 = y * math.cos(radX) - z1 * math.sin(radX);

      return Offset(center.dx + x1, center.dy + y2);
    }).toList();

    final List<List<int>> edges = [
      [0, 1], [1, 2], [2, 3], [3, 0],
      [4, 5], [5, 6], [6, 7], [7, 4],
      [0, 4], [1, 5], [2, 6], [3, 7],
    ];

    if (floor == 2 && projected.length >= 12) {
      edges.addAll([
        [8, 9], [9, 10], [10, 11], [11, 8],
        [4, 8], [5, 9], [6, 10], [7, 11],
      ]);
    }

    final edgePaint = Paint()
      ..color = isWireframe ? KazaTheme.accentGold : KazaTheme.primaryCoral
      ..strokeWidth = isWireframe ? 1.5 : 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = KazaTheme.primaryCoral.withValues(alpha: isWireframe ? 0.05 : 0.25)
      ..style = PaintingStyle.fill;

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

    for (final edge in edges) {
      canvas.drawLine(projected[edge[0]], projected[edge[1]], edgePaint);
    }

    final nodePaint = Paint()..color = KazaTheme.accentGold;
    for (final pt in projected) {
      canvas.drawCircle(pt, 3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VirtualModel3DPainter oldDelegate) => true;
}
