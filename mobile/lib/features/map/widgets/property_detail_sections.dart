// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../providers/map_properties_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/widgets/kaza_pin_painter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS — Glass design tokens for the property sheet
// ─────────────────────────────────────────────────────────────────────────────
const _sectionPad = EdgeInsets.fromLTRB(20, 20, 20, 22);
const _hairline = Color(0x140F1F2E); // azulKaza @ 8%

/// Translucent "glass" surface used by every card of the property sheet.
BoxDecoration propertyGlassDecoration({double radius = 22, double opacity = 0.66}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
    boxShadow: [
      BoxShadow(
        color: KazaTheme.azulKaza.withValues(alpha: 0.06),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

/// Frosted circle/pill used for controls that float over photos.
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final bool dark;
  final String? tooltip;

  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.radius = 999,
    this.onTap,
    this.dark = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final pill = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: dark
              ? KazaTheme.azulKaza.withValues(alpha: 0.38)
              : Colors.white.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: Colors.white.withValues(alpha: dark ? 0.25 : 0.8)),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

/// Inserts thousand separators into bare digit runs ("USD 350555" → "USD 350.555").
String formatPropertyPrice(String raw) {
  return raw.replaceAllMapped(RegExp(r'(?<![\d.,])\d{4,}(?![\d.,])'), (m) {
    final digits = m[0]!;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  });
}

List<String> propertyPhotos(PropertyMapItem p) {
  final raw = p.photos.isNotEmpty ? p.photos : (p.imageUrl != null ? [p.imageUrl!] : <String>[]);
  return raw.where((url) => !url.contains('/360_')).toList();
}

Widget _sectionTitle(String num, String title, {IconData? icon}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (icon != null) ...[
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KazaTheme.azulKaza.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: KazaTheme.azulKaza),
        ),
        const SizedBox(width: 12),
      ],
      Flexible(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: KazaTheme.azulKaza,
          ),
        ),
      ),
    ],
  );
}

Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: propertyGlassDecoration(),
    child: Padding(
      padding: padding ?? _sectionPad,
      child: child,
    ),
  );
}

Widget _subTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: KazaTheme.azulKaza.withValues(alpha: 0.55),
        ),
      ),
    );

Widget _divider() => const Divider(color: _hairline, height: 32, thickness: 1);

Widget _detailRow(IconData icon, String label, String value, {Color? valueColor, Widget? trailing}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: KazaTheme.grisMedio),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: KazaTheme.textSecondary),
          ),
        ),
        if (trailing != null)
          trailing
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? KazaTheme.azulKaza,
            ),
          ),
      ],
    ),
  );
}

Widget _softChip(String label, {IconData? icon, Color color = KazaTheme.azulKaza, bool dot = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
        ],
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL-SCREEN GALLERY
// ─────────────────────────────────────────────────────────────────────────────
void openPropertyGallery(BuildContext context, List<String> photos, int initialIndex,
    {ValueChanged<int>? onChanged}) {
  if (photos.isEmpty) return;
  final controller = PageController(initialPage: initialIndex);
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.94),
    barrierDismissible: true,
    barrierLabel: 'Galería',
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      int localIndex = initialIndex;
      return StatefulBuilder(builder: (context, setLocal) {
        void go(int delta) {
          final next = (localIndex + delta).clamp(0, photos.length - 1);
          controller.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
        }

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: photos.length,
                onPageChanged: (i) {
                  setLocal(() => localIndex = i);
                  onChanged?.call(i);
                },
                itemBuilder: (context, i) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      photos[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GlassPill(
                  dark: true,
                  tooltip: 'Cerrar',
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
              if (photos.length > 1) ...[
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GlassPill(
                      dark: true,
                      onTap: localIndex > 0 ? () => go(-1) : null,
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GlassPill(
                      dark: true,
                      onTap: localIndex < photos.length - 1 ? () => go(1) : null,
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ],
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: Center(
                  child: GlassPill(
                    dark: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text(
                      '${localIndex + 1} / ${photos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO GALLERY — full-bleed carousel shown behind the collapsing app bar
// ─────────────────────────────────────────────────────────────────────────────
class PropertyHeroGallery extends StatefulWidget {
  final PropertyMapItem property;
  final double sheetRadius;
  final Color sheetColor;

  const PropertyHeroGallery({
    super.key,
    required this.property,
    this.sheetRadius = 28,
    this.sheetColor = KazaTheme.grisClaro,
  });

  @override
  State<PropertyHeroGallery> createState() => _PropertyHeroGalleryState();
}

class _PropertyHeroGalleryState extends State<PropertyHeroGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta, int total) {
    final next = (_index + delta).clamp(0, total - 1);
    _controller.animateToPage(next, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final photos = propertyPhotos(widget.property);
    final wide = MediaQuery.of(context).size.width >= 720;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (photos.isEmpty)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KazaTheme.azulKaza, Color(0xFF1C3550)],
              ),
            ),
            child: Center(
              child: Icon(Icons.photo_camera_outlined, size: 56, color: Colors.white.withValues(alpha: 0.4)),
            ),
          )
        else
          PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => openPropertyGallery(context, photos, i,
                  onChanged: (n) => _controller.jumpToPage(n)),
              child: Image.network(
                photos[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: KazaTheme.azulKaza,
                  child: const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                ),
              ),
            ),
          ),

        // Top scrim keeps floating controls legible over bright photos.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.28, 0.7, 1],
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.22),
                ],
              ),
            ),
          ),
        ),

        if (wide && photos.length > 1) ...[
          Positioned(
            left: 20,
            top: 0,
            bottom: widget.sheetRadius,
            child: Center(
              child: AnimatedOpacity(
                opacity: _index > 0 ? 1 : 0.35,
                duration: const Duration(milliseconds: 200),
                child: GlassPill(
                  tooltip: 'Anterior',
                  onTap: () => _go(-1, photos.length),
                  child: const Icon(Icons.chevron_left_rounded, color: KazaTheme.azulKaza, size: 24),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: widget.sheetRadius,
            child: Center(
              child: AnimatedOpacity(
                opacity: _index < photos.length - 1 ? 1 : 0.35,
                duration: const Duration(milliseconds: 200),
                child: GlassPill(
                  tooltip: 'Siguiente',
                  onTap: () => _go(1, photos.length),
                  child: const Icon(Icons.chevron_right_rounded, color: KazaTheme.azulKaza, size: 24),
                ),
              ),
            ),
          ),
        ],

        if (photos.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: widget.sheetRadius + 14,
            child: Row(
              children: [
                if (photos.length > 1)
                  GlassPill(
                    dark: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        photos.length.clamp(0, 8),
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: i == _index.clamp(0, 7) ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index.clamp(0, 7) ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                GlassPill(
                  dark: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  onTap: () => openPropertyGallery(context, photos, _index,
                      onChanged: (n) => _controller.jumpToPage(n)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 15, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${_index + 1} / ${photos.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Rounded "sheet" edge where the content begins.
        Positioned(
          left: 0,
          right: 0,
          bottom: -1,
          height: widget.sheetRadius + 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.sheetColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(widget.sheetRadius)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 01 · RESUMEN
// ─────────────────────────────────────────────────────────────────────────────
class PropertyHeroSection extends StatelessWidget {
  final PropertyMapItem property;
  final VoidCallback? onScrollToGallery;

  const PropertyHeroSection({
    super.key,
    required this.property,
    this.onScrollToGallery,
  });

  @override
  Widget build(BuildContext context) {
    final specs = <(IconData, String, String)>[
      (Icons.straighten_rounded, property.surface, 'Superficie'),
      (Icons.king_bed_outlined, '${property.bedrooms}', 'Dormitorios'),
      (Icons.bathtub_outlined, '${property.bathrooms}', 'Baños'),
      if (property.parkingSpaces > 0) (Icons.directions_car_outlined, '${property.parkingSpaces}', 'Parqueos'),
    ];

    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _softChip(property.operation, color: KazaTheme.coralKaza),
              _softChip(property.type),
              _softChip('Disponible', color: KazaTheme.verdeEntorno, dot: true),
              if (property.isPlus) const KazaPlusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            property.title,
            style: const TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: KazaTheme.azulKaza,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: KazaTheme.coralKaza),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.address ?? 'Santa Cruz, Bolivia',
                  style: const TextStyle(fontSize: 14, color: KazaTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatPropertyPrice(property.price),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: KazaTheme.azulKaza,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, c) {
            const gap = 10.0;
            final cols = specs.length;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Row(
              children: [
                for (var i = 0; i < specs.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(width: w, child: _specTile(specs[i].$1, specs[i].$2, specs[i].$3)),
                ],
              ],
            );
          }),
          const SizedBox(height: 18),
          Row(
            children: [
              KazaTrustBadge(label: property.trustLabel, isOrganization: property.isOrg),
              const Spacer(),
              Text(
                'ID KZA-${property.id.length >= 8 ? property.id.substring(0, 8) : property.id}',
                style: TextStyle(fontSize: 11, color: KazaTheme.textSecondary.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specTile(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: KazaTheme.azulKaza.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _hairline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: KazaTheme.azulKaza),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 03 · DETALLES DE LA PROPIEDAD
// ─────────────────────────────────────────────────────────────────────────────
class PropertyDetailsSection extends StatelessWidget {
  final PropertyMapItem property;

  const PropertyDetailsSection({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String, String)>[
      (Icons.straighten_rounded, 'Área total', property.surface),
      if (property.coveredSurface != null) (Icons.home_outlined, 'Área construida', property.coveredSurface!),
      (Icons.king_bed_outlined, 'Dormitorios', '${property.bedrooms}'),
      (Icons.bathtub_outlined, 'Baños', '${property.bathrooms}'),
      if (property.parkingSpaces > 0) (Icons.directions_car_outlined, 'Parqueos', '${property.parkingSpaces}'),
      (Icons.layers_outlined, 'Pisos', '${property.floorsTotal}'),
      (Icons.history_rounded, 'Antigüedad', property.ageYears > 0 ? '${property.ageYears} años' : 'A estrenar'),
      (Icons.apartment_outlined, 'Tipo', property.type),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('03', 'Detalles de la propiedad', icon: Icons.tune_rounded),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 560 ? 3 : 2;
            const gap = 10.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: facts.map((f) => SizedBox(width: w, child: _factTile(f.$1, f.$2, f.$3))).toList(),
            );
          }),
          _divider(),
          _detailRow(Icons.check_circle_outline, 'Estado', 'Disponible', valueColor: KazaTheme.verdeEntorno),
          _detailRow(Icons.sell_outlined, 'Operación', property.operation),
        ],
      ),
    );
  }

  Widget _factTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KazaTheme.azulKaza.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KazaTheme.grisMedio),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: KazaTheme.azulKaza),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 04 · DESCRIPCIÓN Y DESTACADOS
// ─────────────────────────────────────────────────────────────────────────────
class PropertyDescriptionSection extends StatefulWidget {
  final PropertyMapItem property;
  const PropertyDescriptionSection({super.key, required this.property});

  @override
  State<PropertyDescriptionSection> createState() => _PropertyDescriptionSectionState();
}

class _PropertyDescriptionSectionState extends State<PropertyDescriptionSection> {
  bool _expanded = false;

  static const _idealFor = ['Familias', 'Inversión', 'Profesionales'];

  @override
  Widget build(BuildContext context) {
    final fullText = widget.property.description?.isNotEmpty == true
        ? widget.property.description!
        : 'Sin descripción detallada. Contacta al anunciante para más información.';

    final displayText = (_expanded || fullText.length < 120) ? fullText : '${fullText.substring(0, 120)}...';

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('04', 'Descripción', icon: Icons.description_outlined),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Text(
              displayText,
              style: const TextStyle(fontSize: 15, color: KazaTheme.textSecondary, height: 1.65),
            ),
          ),
          if (fullText.length >= 120)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Ver menos' : 'Leer más',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: KazaTheme.coralKaza),
                      ),
                      Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 18, color: KazaTheme.coralKaza),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.property.highlights.isNotEmpty) ...[
            _divider(),
            _subTitle('Destacados'),
            ...widget.property.highlights.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_rounded, size: 18, color: KazaTheme.verdeEntorno),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(h, style: const TextStyle(fontSize: 14, color: KazaTheme.textSecondary, height: 1.45)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 05 · AMENIDADES Y CARACTERÍSTICAS
// ─────────────────────────────────────────────────────────────────────────────
class PropertyAmenitiesSection extends StatelessWidget {
  final PropertyMapItem property;
  const PropertyAmenitiesSection({super.key, required this.property});

  IconData _getIconForAmenity(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('piscina')) return Icons.pool;
    if (lower.contains('gimnasio') || lower.contains('gym')) return Icons.fitness_center;
    if (lower.contains('coworking') || lower.contains('oficina')) return Icons.computer_outlined;
    if (lower.contains('eventos') || lower.contains('salon')) return Icons.celebration_outlined;
    if (lower.contains('churrasquera') || lower.contains('parrilla')) return Icons.outdoor_grill_outlined;
    if (lower.contains('parque') || lower.contains('infantil')) return Icons.child_friendly_outlined;
    if (lower.contains('seguridad')) return Icons.security;
    if (lower.contains('ascensor')) return Icons.elevator_outlined;
    if (lower.contains('pet')) return Icons.pets;
    if (lower.contains('aire')) return Icons.ac_unit;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('05', 'Amenidades', icon: Icons.auto_awesome_outlined),
          const SizedBox(height: 18),
          if (property.amenities.isEmpty)
            const Text(
              'No se especificaron amenidades.',
              style: TextStyle(fontSize: 14, color: KazaTheme.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: property.amenities.map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: KazaTheme.azulKaza.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIconForAmenity(amenity), size: 16, color: KazaTheme.azulKaza),
                      const SizedBox(width: 8),
                      Text(
                        amenity,
                        style: const TextStyle(fontSize: 13, color: KazaTheme.azulKaza, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          _divider(),
          _subTitle('Edificio'),
          _detailRow(Icons.business_outlined, 'Torre', '${property.floorsTotal} pisos'),
          _detailRow(Icons.elevator_outlined, 'Ascensores', 'Sí'),
          _detailRow(Icons.local_parking_outlined, 'Parqueo para visitas', property.parkingSpaces > 0 ? 'Sí' : 'No'),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// 06 · DISPONIBILIDAD Y FRESCURA
// ─────────────────────────────────────────────────────────────────────────────
class PropertyAvailabilitySection extends StatelessWidget {
  const PropertyAvailabilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('06', 'Disponibilidad', icon: Icons.update_outlined),
          const SizedBox(height: 16),

          const Text(
            'Distinguimos disponibilidad de frescura',
            style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 14),

          // Disponibilidad row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Disponibilidad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: KazaTheme.verdeEntorno.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: KazaTheme.verdeEntorno.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 7, height: 7, decoration: const BoxDecoration(color: KazaTheme.verdeEntorno, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Disponible', style: TextStyle(fontSize: 12, color: KazaTheme.verdeEntorno, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Operación', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: KazaTheme.primaryCoral.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('En Venta', style: TextStyle(fontSize: 12, color: KazaTheme.primaryCoral, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          _divider(),

          // Fechas eliminadas porque no vienen de la BD actualmente (eran ficticias)
          
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFFF9A825)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La disponibilidad puede cambiar. Verifica contactando al anunciante.',
                    style: TextStyle(fontSize: 11, color: Colors.brown.shade600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 07 · UBICACIÓN Y ENTORNO
// ─────────────────────────────────────────────────────────────────────────────
class PropertyLocationSection extends StatelessWidget {
  final PropertyMapItem property;
  
  const PropertyLocationSection({super.key, required this.property});

  static const _distances = [
    {'place': 'Mall Ventura', 'dist': '< 5 min', 'km': '1.2 km', 'icon': Icons.local_mall_outlined},
    {'place': 'Supermercado', 'dist': '< 3 min', 'km': '850 m', 'icon': Icons.shopping_cart_outlined},
    {'place': 'Parques Marques', 'dist': '< 3 min', 'km': '700 m', 'icon': Icons.park_outlined},
    {'place': 'Aeropuerto Viru Viru', 'dist': '< 24 min', 'km': '15 km', 'icon': Icons.flight_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('07', 'Ubicación', icon: Icons.map_outlined),
          const SizedBox(height: 16),

                    Row(
            children: [
              const Icon(Icons.location_pin, size: 16, color: KazaTheme.primaryCoral),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  property.address ?? 'Ubicación exacta no especificada',
                  style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Real Map
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: property.location,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kaza.app',
                        maxNativeZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: property.location,
                            width: 140,
                            height: 60,
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: KazaTheme.primaryCoral,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [BoxShadow(color: KazaTheme.primaryCoral.withValues(alpha: 0.4), blurRadius: 8)],
                                  ),
                                  child: const Text('Ubicación de la propiedad', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                CustomPaint(
                                  size: const Size(16, 8),
                                  painter: _TrianglePainter(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Ver en mapa
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: KazaTheme.azulKaza,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.open_in_new, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Ver en Mapa', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _mapToggle(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? KazaTheme.azulKaza : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : KazaTheme.textSecondary,
        ),
      ),
    );
  }
}

// Mini map grid painter
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB2DFDB).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Simulated streets
    final streetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 6;
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), streetPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = KazaTheme.primaryCoral;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 08 · ANUNCIANTE / PUBLICADOR
// ─────────────────────────────────────────────────────────────────────────────
class PropertyAgentSection extends StatelessWidget {
  const PropertyAgentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('08', 'Anunciante', icon: Icons.store_mall_directory_outlined),
          const SizedBox(height: 16),

          // Agent card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: KazaTheme.azulKaza,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Torres Sky Park', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
                    const SizedBox(height: 2),
                    const Text('Desarrolladora Inmobiliaria', style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
                    const SizedBox(height: 6),
                    // Verification chips
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _verifyChip('Identidad verificada'),
                        _verifyChip('Empresa verificada'),
                        _verifyChip('Documentos verificados'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _agentStat('25', 'Publicaciones'),
              _statDivider(),
              _agentStat('4.8 ⭐', 'Calificación'),
              _statDivider(),
              _agentStat('3 años', 'Miembro en\nKAZA'),
            ],
          ),

          _divider(),

          // Sobre el anunciante
          _subTitle('Sobre el anunciante'),
          const Text(
            'Desarrollamos proyectos inmobiliarios innovadores con los más altos estándares de calidad y compromiso con nuestros clientes.',
            style: TextStyle(fontSize: 13, color: KazaTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: KazaTheme.azulKaza,
              side: const BorderSide(color: KazaTheme.azulKaza),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.grid_view_outlined, size: 16),
            label: const Text('Ver todas sus propiedades', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _verifyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: KazaTheme.verdeEntorno.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: KazaTheme.verdeEntorno.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 10, color: KazaTheme.verdeEntorno),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: KazaTheme.verdeEntorno, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _agentStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 36, color: _hairline);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 09 · DOCUMENTOS Y LEGALES
// ─────────────────────────────────────────────────────────────────────────────
class PropertyDocumentsSection extends StatelessWidget {
  const PropertyDocumentsSection({super.key});

  static const _docs = [
    {'name': 'Plano del departamento', 'size': 'PDF · 990 KB'},
    {'name': 'Plano del piso', 'size': 'PDF · 1.1 MB'},
    {'name': 'Memoria de subdivisión', 'size': 'PDF · 3.5 MB'},
    {'name': 'Ficha técnica del proyecto', 'size': 'PDF · 750 KB'},
  ];

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('09', 'Documentos y legales', icon: Icons.folder_outlined),
          const SizedBox(height: 16),

          _subTitle('Documentos'),

          ..._docs.map(
            (d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, size: 20, color: Color(0xFFFF3B30)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KazaTheme.azulKaza)),
                        Text(d['size']!, style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.download_outlined, size: 20, color: KazaTheme.azulKaza),
                ],
              ),
            ),
          ),

          _divider(),

          _subTitle('Información legal'),

          _legalRow('Título de propiedad', 'Verificado', isVerified: true),
          _legalRow('Uso de suelo', 'Residencial'),
          _legalRow('Reglamento de copropiedad', 'Disponible'),
          _legalRow('Impuestos al día', 'Verificado', isVerified: true),

          _divider(),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KazaTheme.azulKaza.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: KazaTheme.grisMedio),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ID Anuncio: ARG-TRS-8501',
                    style: TextStyle(fontSize: 11, color: KazaTheme.textSecondary.withValues(alpha: 0.8)),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: KazaTheme.primaryCoral,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Ver avisos y disclaimers', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalRow(String label, String status, {bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isVerified ? KazaTheme.verdeEntorno.withValues(alpha: 0.1) : KazaTheme.azulKaza.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isVerified ? KazaTheme.verdeEntorno : KazaTheme.azulKaza,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10 · GUARDAR, COMPARAR Y COMPARTIR
// ─────────────────────────────────────────────────────────────────────────────
class PropertySaveShareSection extends StatelessWidget {
  final PropertyMapItem property;
  final VoidCallback? onSave;

  const PropertySaveShareSection({super.key, required this.property, this.onSave});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('10', 'Guardar y comparar', icon: Icons.bookmark_border_outlined),
          const SizedBox(height: 16),

          _subTitle('Acciones rápidas'),

          Row(
            children: [
              _quickAction(Icons.bookmark_add_outlined, 'Guardar\npropiedad', () => onSave?.call()),
              const SizedBox(width: 8),
              _quickAction(Icons.share_outlined, 'Compartir', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔗 Enlace copiado')),
                );
              }),
              const SizedBox(width: 8),
              _quickAction(Icons.download_outlined, 'Descargar\nficha', () {}),
            ],
          ),

          _divider(),

          _subTitle('Comparar con otras'),

          // Compare cards placeholder
          Row(
            children: [
              Expanded(
                child: _compareCard(
                  title: 'Departamento en venta\nEquipetrol Norte',
                  spec: '120 m² · 3D · 2B',
                  selected: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _compareCard(
                  title: 'Departamento en venta\nEquipetrol Norte',
                  spec: '115 m² · 3D · 2B',
                  selected: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: KazaTheme.azulKaza,
                side: const BorderSide(color: KazaTheme.azulKaza),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.compare_arrows_outlined, size: 18),
              label: const Text('Ver comparador (2)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: KazaTheme.azulKaza.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hairline),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: KazaTheme.azulKaza),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: KazaTheme.azulKaza, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compareCard({required String title, required String spec, required bool selected}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? KazaTheme.azulKaza.withValues(alpha: 0.04) : KazaTheme.grisClaro,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? KazaTheme.azulKaza.withValues(alpha: 0.3) : _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(color: KazaTheme.grisClaro, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.home_work_outlined, color: KazaTheme.grisMedio)),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: KazaTheme.azulKaza), maxLines: 2),
          const SizedBox(height: 2),
          Text(spec, style: const TextStyle(fontSize: 10, color: KazaTheme.textSecondary)),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Esta propiedad', style: TextStyle(fontSize: 10, color: KazaTheme.primaryCoral, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 11 · CONTACTO Y VISITAS
// ─────────────────────────────────────────────────────────────────────────────
class PropertyContactSection extends StatelessWidget {
  const PropertyContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('11', 'Contacto y visitas', icon: Icons.contact_phone_outlined),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KazaTheme.azulKaza.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: KazaTheme.azulKaza.withValues(alpha: 0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: KazaTheme.azulKaza),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contactar anunciante\nTu conversación es directa y segura.',
                    style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _contactButton(
            context,
            icon: Icons.chat_bubble_outline,
            label: 'Mensajería en KAZA',
            subtitle: 'Responde dentro de la app',
            color: KazaTheme.azulKaza,
            onTap: () => _snack(context, '💬 Abriendo chat KAZA...'),
          ),
          const SizedBox(height: 8),
          _contactButton(
            context,
            icon: Icons.chat_bubble_rounded,
            label: 'WhatsApp',
            subtitle: 'Contactar por WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => _snack(context, '📱 Abriendo WhatsApp...'),
          ),
          const SizedBox(height: 8),
          _contactButton(
            context,
            icon: Icons.phone_outlined,
            label: 'Llamar',
            subtitle: 'Llamada telefónica',
            color: KazaTheme.trustBlue,
            onTap: () => _snack(context, '📞 Iniciando llamada...'),
          ),

          _divider(),

          // Agendar visita
          _subTitle('Agendar visita'),
          const Text(
            'Coordina una visita directa al inmueble.',
            style: TextStyle(fontSize: 13, color: KazaTheme.textSecondary),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _snack(context, '📅 Abriendo calendario de visitas...'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.primaryCoral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Agendar visita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: KazaTheme.azulKaza));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 12 · REPORTAR PUBLICACIÓN
// ─────────────────────────────────────────────────────────────────────────────
class PropertyReportSection extends StatefulWidget {
  const PropertyReportSection({super.key});

  @override
  State<PropertyReportSection> createState() => _PropertyReportSectionState();
}

class _PropertyReportSectionState extends State<PropertyReportSection> {
  bool _expanded = false;
  String? _selected;
  bool _submitted = false;
  final _controller = TextEditingController();

  static const _motivos = [
    'Información incorrecta',
    'Propiedad no disponible',
    'Precio incorrecto',
    'Fotos engañosas',
    'Contenido inapropiado',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(child: _sectionTitle('12', 'Reportar publicación', icon: Icons.flag_outlined)),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: KazaTheme.grisMedio,
                ),
              ],
            ),
          ),

          if (_expanded) ...[
            const SizedBox(height: 16),

            if (_submitted)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KazaTheme.verdeEntorno.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KazaTheme.verdeEntorno.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: KazaTheme.verdeEntorno, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡Tu reporte fue recibido.\nNuestro equipo lo revisará.',
                        style: TextStyle(fontSize: 13, color: KazaTheme.verdeEntorno, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _subTitle('Motivo del reporte'),

              ..._motivos.map(
                (m) => GestureDetector(
                  onTap: () => setState(() => _selected = m),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selected == m ? KazaTheme.primaryCoral : KazaTheme.grisMedio,
                              width: 2,
                            ),
                          ),
                          child: _selected == m
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: KazaTheme.primaryCoral,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(m, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _subTitle('Comentarios adicionales (opcional)'),
              TextField(
                controller: _controller,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, color: KazaTheme.azulKaza),
                decoration: InputDecoration(
                  hintText: 'Cuéntanos más detalles...',
                  hintStyle: TextStyle(fontSize: 13, color: KazaTheme.grisMedio),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: KazaTheme.azulKaza),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: KazaTheme.grisClaro,
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => setState(() => _submitted = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KazaTheme.primaryCoral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: KazaTheme.grisMedio.withValues(alpha: 0.3),
                  ),
                  child: const Text('Enviar reporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
