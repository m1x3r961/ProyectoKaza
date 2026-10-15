import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../messages/screens/chat_detail_screen.dart';
// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../providers/map_properties_provider.dart';
import '../../saved/screens/saved_screen.dart';
import '../widgets/property_detail_sections.dart';
import '../../properties/screens/tour_360_local_screen.dart';
import '../../shell/screens/main_shell_screen.dart';

/// 🏠 PROPERTY DETAIL SCREEN — Ficha Completa de Propiedad KAZA v2
/// Prototipo B16 · Ficha completa con 12 secciones
class PropertyDetailScreen extends ConsumerStatefulWidget {
  final PropertyMapItem property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;
  double _collapseOffset = 220;

  // 2D floor plan state
  int _selectedRoomIndex = 0;

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
      final show = _scrollController.offset > _collapseOffset;
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
  Future<void> _contact() async {
    if (SupabaseConfig.client.auth.currentUser == null) {
      checkProgressiveAuth(
          context: context,
          ref: ref,
          actionName: 'contactar',
          onAuthenticatedAction: () => _contact());
      return;
    }
    try {
      final result = await ApiClient().request(
          '/api/conversations/property/${widget.property.id}',
          method: 'POST');
      if (mounted)
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                    title: widget.property.title,
                    conversationId: result['id'] as String)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo iniciar la conversación. Reintentá.')));
    }
  }

  Future<void> _saveProperty() async {
    if (SupabaseConfig.client.auth.currentUser == null) {
      checkProgressiveAuth(
          context: context,
          ref: ref,
          actionName: 'guardar',
          onAuthenticatedAction: () => _saveProperty());
      return;
    }
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final payload = {'property_id': widget.property.id};
      if (userId != null) payload['user_id'] = userId;
      await SupabaseConfig.client.from('saved_properties').upsert(payload,
          onConflict: 'user_id,property_id', ignoreDuplicates: true);
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
        SnackBar(
            content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  static const double _maxContentWidth = 880;
  static const double _sheetRadius = 28;

  double _heroHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return (size.width * 0.62).clamp(300.0, math.min(560.0, size.height * 0.62));
  }

  Widget _glassAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GlassPill(
        tooltip: tooltip,
        padding: const EdgeInsets.all(9),
        onTap: onTap,
        child: Icon(icon, size: 20, color: KazaTheme.azulKaza),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroHeight = _heroHeight(context);
    _collapseOffset = heroHeight - kToolbarHeight - MediaQuery.of(context).padding.top - 24;
    final sidePad = math.max(0.0, (size.width - _maxContentWidth) / 2);
    // The shell's AI button floats bottom-right; keep the CTA clear of it.
    final insideShell = context.findAncestorWidgetOfExactType<MainShellScreen>() != null;
    final reserveFab = insideShell && sidePad < 88;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_showStickyHeader ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: KazaTheme.grisClaro,
        extendBody: true,
        body: Stack(
          children: [
            // Soft colour fields behind the glass cards.
            Positioned(
              top: heroHeight + 40,
              right: -120,
              child: _glow(KazaTheme.coralKaza, 420, 0.22),
            ),
            Positioned(
              top: heroHeight + 520,
              left: -160,
              child: _glow(KazaTheme.azulKaza, 520, 0.16),
            ),
            Positioned(
              bottom: -140,
              right: -100,
              child: _glow(KazaTheme.accentGold, 420, 0.26),
            ),
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  expandedHeight: heroHeight,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  leadingWidth: 64,
                  leading: Center(
                    child: _glassAction(
                      Icons.arrow_back_ios_new_rounded,
                      'Volver',
                      () => Navigator.maybePop(context),
                    ),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          formatPropertyPrice(widget.property.price),
                          style: const TextStyle(
                            color: KazaTheme.coralKaza,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    _glassAction(Icons.bookmark_border_rounded, 'Guardar', _saveProperty),
                    _glassAction(Icons.ios_share_rounded, 'Compartir', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🔗 Enlace copiado')),
                      );
                    }),
                    const SizedBox(width: 12),
                  ],
                  flexibleSpace: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Frosted bar once the photo has scrolled away.
                      AnimatedOpacity(
                        opacity: _showStickyHeader ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.72),
                                border: Border(
                                  bottom: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.08)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        stretchModes: const [StretchMode.zoomBackground],
                        background: PropertyHeroGallery(
                          property: widget.property,
                          sheetRadius: _sheetRadius,
                          sheetColor: KazaTheme.grisClaro,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(sidePad, 0, sidePad, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      PropertyHeroSection(property: widget.property),
                      PropertyDetailsSection(property: widget.property),
                      PropertyDescriptionSection(property: widget.property),
                      PropertyAmenitiesSection(property: widget.property),
                      _buildVirtualTourCard(),
                      _buildFinancingBanner(context),
                      PropertyLocationSection(property: widget.property),
                      const PropertyAvailabilitySection(),
                      const PropertyAgentSection(),
                      const PropertyDocumentsSection(),
                      PropertySaveShareSection(property: widget.property, onSave: _saveProperty),
                      const PropertyContactSection(),
                      const PropertyReportSection(),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Sticky glass CTA ───────────────────────────────────────────────
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                border: Border(top: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.08))),
              ),
              padding: EdgeInsets.only(
                left: 20 + sidePad,
                right: (reserveFab ? 88 : 20) + (reserveFab ? 0 : sidePad),
                top: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.property.operation,
                          style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatPropertyPrice(widget.property.price),
                            style: const TextStyle(
                              color: KazaTheme.azulKaza,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KazaTheme.coralKaza,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text(
                          'Contactar',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        onPressed: _contact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glow(Color color, double size, double alpha) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  // ─── FINANCING BANNER ───────────────────────────────────────────────────────
  Widget _buildFinancingBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KazaTheme.azulKaza, Color(0xFF1B3550)],
        ),
        boxShadow: [
          BoxShadow(
            color: KazaTheme.azulKaza.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financiamiento disponible',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                SizedBox(height: 2),
                Text('Compara opciones con entidades financieras',
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GlassPill(
            dark: true,
            tooltip: 'Ver opciones de financiamiento',
            onTap: () => context.push('/financing'),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: KazaTheme.azulKaza, shape: BoxShape.circle),
                  child: const Text('03b',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.architecture,
                    size: 18, color: KazaTheme.azulKaza),
                const SizedBox(width: 6),
                const Text('Plano 2D Interactivo',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KazaTheme.azulKaza)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color:
                              isSel ? KazaTheme.azulKaza : KazaTheme.grisClaro,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel
                                ? KazaTheme.azulKaza
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(r['icon'] as IconData,
                                size: 14,
                                color: isSel
                                    ? Colors.white
                                    : KazaTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              r['name'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSel
                                    ? Colors.white
                                    : KazaTheme.textPrimary,
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
                      painter: FloorPlan2DPainter(
                          rooms: _rooms, selectedIndex: _selectedRoomIndex),
                    ),
                    // Room info overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8)
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(_rooms[_selectedRoomIndex]['icon'] as IconData,
                                color: _rooms[_selectedRoomIndex]['color']
                                    as Color,
                                size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      _rooms[_selectedRoomIndex]['name']
                                          as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: KazaTheme.azulKaza)),
                                  Text(
                                    '${_rooms[_selectedRoomIndex]['dimensions']} · ${_rooms[_selectedRoomIndex]['surface']}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: KazaTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (_rooms[_selectedRoomIndex]['color']
                                        as Color)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _rooms[_selectedRoomIndex]['surface'] as String,
                                style: TextStyle(
                                    color: _rooms[_selectedRoomIndex]['color']
                                        as Color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
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

  // ─── VISOR 360° REAL CON IMÁGENES PANORÁMICAS ────────────────────────────────
  Widget _buildVirtualTourCard() {
    final images = widget.property.photos.where((url) => url.contains('/360_')).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    // Creamos escenas ficticias basadas en el número de fotos 360 reales
    final scenes = List.generate(images.length, (i) => ('Escena ${i + 1}', '👁️'));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: propertyGlassDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: KazaTheme.azulKaza.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.view_in_ar_rounded, size: 18, color: KazaTheme.azulKaza),
                ),
                const SizedBox(width: 12),
                const Text('Tour Virtual 360°',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: KazaTheme.azulKaza)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KazaTheme.coralKaza.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: KazaTheme.coralKaza.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                              color: KazaTheme.coralKaza,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('${images.length} escenas',
                          style: const TextStyle(
                              color: KazaTheme.coralKaza,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Preview strip
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              itemBuilder: (ctx, i) {
                final (label, emoji) = scenes[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Tour360LocalScreen(
                          propertyTitle: widget.property.title,
                          assetImages: images,
                        ),
                      )),
                  child: Container(
                    width: 96,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 3),
                            color: Colors.black.withValues(alpha: 0.55),
                            child: Text(
                              '$emoji $label',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // ── Botón principal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.azulKaza,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
              label: const Text('Iniciar Tour 360° Inmersivo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Tour360LocalScreen(
                      propertyTitle: widget.property.title,
                      assetImages: images,
                    ),
                  )),
            ),
          ),
        ],
      ),
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

      canvas.drawRRect(
          RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
          fillPaint);
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
      [-100, 60, -80],
      [100, 60, -80],
      [100, 60, 80],
      [-100, 60, 80],
      [-100, -20, -80],
      [100, -20, -80],
      [100, -20, 80],
      [-100, -20, 80],
    ];

    if (floor == 2) {
      rawVertices.addAll([
        [-60, -90, -50],
        [60, -90, -50],
        [60, -90, 50],
        [-60, -90, 50],
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
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 0],
      [4, 5],
      [5, 6],
      [6, 7],
      [7, 4],
      [0, 4],
      [1, 5],
      [2, 6],
      [3, 7],
    ];

    if (floor == 2 && projected.length >= 12) {
      edges.addAll([
        [8, 9],
        [9, 10],
        [10, 11],
        [11, 8],
        [4, 8],
        [5, 9],
        [6, 10],
        [7, 11],
      ]);
    }

    final edgePaint = Paint()
      ..color = isWireframe ? KazaTheme.accentGold : KazaTheme.primaryCoral
      ..strokeWidth = isWireframe ? 1.5 : 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color =
          KazaTheme.primaryCoral.withValues(alpha: isWireframe ? 0.05 : 0.25)
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
