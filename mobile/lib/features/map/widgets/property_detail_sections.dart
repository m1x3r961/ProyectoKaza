// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_badges.dart';
import '../providers/map_properties_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
const _sectionPad = EdgeInsets.symmetric(horizontal: 20, vertical: 20);

Widget _sectionTitle(String num, String title, {IconData? icon}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: KazaTheme.azulKaza,
          shape: BoxShape.circle,
        ),
        child: Text(
          num,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 10),
      if (icon != null) ...[
        Icon(icon, size: 18, color: KazaTheme.azulKaza),
        const SizedBox(width: 6),
      ],
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: KazaTheme.azulKaza,
        ),
      ),
    ],
  );
}

Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
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
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: padding ?? _sectionPad,
      child: child,
    ),
  );
}

Widget _divider() => const Divider(color: Color(0xFFE2E8F0), height: 24);

Widget _detailRow(IconData icon, String label, String value, {Color? valueColor, Widget? trailing}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 18, color: KazaTheme.grisMedio),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: KazaTheme.textSecondary,
            ),
          ),
        ),
        if (trailing != null)
          trailing
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? KazaTheme.azulKaza,
            ),
          ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 01 · RESUMEN / HERO
// ─────────────────────────────────────────────────────────────────────────────
class PropertyHeroSection extends StatelessWidget {
  final PropertyMapItem property;
  final VoidCallback onScrollToGallery;

  const PropertyHeroSection({
    super.key,
    required this.property,
    required this.onScrollToGallery,
  });

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('01', 'Resumen', icon: Icons.home_outlined),
          const SizedBox(height: 16),

          // Imagen Hero
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: property.imageUrl != null
                ? Image.network(
                    property.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(200),
                  )
                : _placeholderImage(200),
          ),
          const SizedBox(height: 14),

          // Badges
          Row(
            children: [
              if (property.isPlus) ...[
                const KazaPlusBadge(),
                const SizedBox(width: 8),
              ],
              KazaTrustBadge(
                label: property.trustLabel,
                isOrganization: property.isOrg,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: KazaTheme.verdeEntorno.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KazaTheme.verdeEntorno.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 12, color: KazaTheme.verdeEntorno),
                    const SizedBox(width: 4),
                    const Text(
                      'Verificado',
                      style: TextStyle(
                        color: KazaTheme.verdeEntorno,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Título y ubicación
          Text(
            property.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: KazaTheme.azulKaza,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: KazaTheme.primaryCoral),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.address ?? 'Santa Cruz, Bolivia',
                  style: const TextStyle(fontSize: 12, color: KazaTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Specs horizontales
          Row(
            children: [
              _heroSpecItem(Icons.straighten, property.surface),
              _heroSpecItem(Icons.king_bed_outlined, '${property.bedrooms} Dorm'),
              _heroSpecItem(Icons.bathtub_outlined, '${property.bathrooms} Baños'),
              if (property.parkingSpaces > 0)
                _heroSpecItem(Icons.local_parking_outlined, '${property.parkingSpaces} Park'),
            ],
          ),
          const SizedBox(height: 16),

          // Estado + Operación
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: KazaTheme.semanticSuccess.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KazaTheme.semanticSuccess.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 13, color: KazaTheme.semanticSuccess),
                    const SizedBox(width: 4),
                    const Text('Disponible', style: TextStyle(fontSize: 11, color: KazaTheme.semanticSuccess, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                property.operation,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
              ),
              const Spacer(),
              Text(
                property.type,
                style: TextStyle(fontSize: 11, color: KazaTheme.textSecondary.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CTA Principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('💬 Iniciando contacto con el anunciante...'),
                    backgroundColor: KazaTheme.primaryCoral,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.primaryCoral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Consultar precio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          // Agente
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: KazaTheme.primaryCoral,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.agentName ?? 'Anunciante KAZA',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
                    ),
                    Text(
                      property.contactPhone ?? 'Ver datos de contacto',
                      style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KazaTheme.primaryCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  property.operation,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: KazaTheme.primaryCoral,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroSpecItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: KazaTheme.azulKaza),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: KazaTheme.grisClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.photo_library_outlined, size: 48, color: KazaTheme.grisMedio),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 02 · GALERÍA DE FOTOS
// ─────────────────────────────────────────────────────────────────────────────
class PropertyGallerySection extends StatefulWidget {
  final PropertyMapItem property;

  const PropertyGallerySection({super.key, required this.property});

  @override
  State<PropertyGallerySection> createState() => _PropertyGallerySectionState();
}

class _PropertyGallerySectionState extends State<PropertyGallerySection> {
  int _selectedTab = 0; // 0=Fotos, 1=Video, 2=Tour360

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('02', 'Galería de fotos', icon: Icons.photo_library_outlined),
          const SizedBox(height: 14),

          // Media type tabs
          Row(
            children: [
              _mediaTab(0, Icons.photo_camera_outlined, 'Fotos', '5/33'),
              const SizedBox(width: 8),
              _mediaTab(1, Icons.play_circle_outline, 'Video', ''),
              const SizedBox(width: 8),
              _mediaTab(2, Icons.view_in_ar_outlined, 'Tour 360°', ''),
            ],
          ),
          const SizedBox(height: 14),

          // Main image display
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                widget.property.imageUrl != null
                    ? Image.network(
                        widget.property.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _galleryPlaceholder(),
                      )
                    : _galleryPlaceholder(),
                // Close / expand icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '1 / ${widget.property.photos.isEmpty ? 1 : widget.property.photos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Thumbnail strip
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.property.photos.isEmpty ? 1 : widget.property.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isSelected = i == 0;
                final photoUrl = widget.property.photos.isNotEmpty ? widget.property.photos[i] : widget.property.imageUrl;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? KazaTheme.primaryCoral : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: KazaTheme.grisClaro,
                    ),
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.photo, color: KazaTheme.grisMedio),
                          )
                        : const Icon(Icons.photo, color: KazaTheme.grisMedio),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaTab(int index, IconData icon, String label, String badge) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? KazaTheme.azulKaza : KazaTheme.grisClaro,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : KazaTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : KazaTheme.textSecondary,
              ),
            ),
            if (badge.isNotEmpty) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.25) : KazaTheme.azulKaza.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : KazaTheme.azulKaza,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _galleryPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: KazaTheme.grisClaro,
      child: const Center(
        child: Icon(Icons.photo_camera_outlined, size: 56, color: KazaTheme.grisMedio),
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
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('03', 'Detalles de la propiedad', icon: Icons.list_alt_outlined),
          const SizedBox(height: 16),

          // Características principales — header
          const Text(
            'Características principales',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),

          _detailRow(Icons.straighten, 'Área total', property.surface),
          if (property.coveredSurface != null)
            _detailRow(Icons.home_outlined, 'Área construida', property.coveredSurface!),
          _detailRow(Icons.king_bed_outlined, 'Dormitorios', '${property.bedrooms}'),
          _detailRow(Icons.bathtub_outlined, 'Baños', '${property.bathrooms}'),
          if (property.parkingSpaces > 0)
            _detailRow(Icons.local_parking_outlined, 'Parqueos', '${property.parkingSpaces}'),

          _divider(),

          _detailRow(Icons.layers_outlined, 'Piso', '${property.floorsTotal > 1 ? "1 de " : ""}${property.floorsTotal}'),
          _detailRow(Icons.history, 'Antigüedad', property.ageYears > 0 ? '${property.ageYears} años' : 'A estrenar'),
          _detailRow(Icons.apartment_outlined, 'Tipo de propiedad', property.type),

          _divider(),

          const Text(
            'Estado y entrega',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),

          _detailRow(
            Icons.check_circle_outline,
            'Estado',
            'Disponible',
            valueColor: KazaTheme.semanticSuccess,
          ),
          _detailRow(Icons.event_outlined, 'Entrega estimada', 'Inmediata'),
          _detailRow(Icons.fingerprint, 'ID de propiedad', 'KZA-${property.id.substring(0, 8)}'),
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
          _sectionTitle('04', 'Descripción y destacados', icon: Icons.description_outlined),
          const SizedBox(height: 16),

          // Descripción
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary, height: 1.6),
          ),
          if (fullText.length >= 120)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Ver menos' : 'Ver más',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.primaryCoral,
                ),
              ),
            ),

          if (widget.property.highlights.isNotEmpty) ...[
            _divider(),

          // Highlights
            const Text(
              'Highlights',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
            ),
            const SizedBox(height: 10),
            ...widget.property.highlights.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: KazaTheme.verdeEntorno),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(h, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
            _divider(),
          ],

          // Ideal para
          const Text(
            'Ideal para',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),
          Row(
            children: _idealFor.map((label) {
              IconData icon;
              switch (label) {
                case 'Familias':
                  icon = Icons.family_restroom;
                  break;
                case 'Inversión':
                  icon = Icons.trending_up;
                  break;
                default:
                  icon = Icons.business_center_outlined;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: KazaTheme.grisClaro,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 24, color: KazaTheme.azulKaza),
                    ),
                    const SizedBox(height: 4),
                    Text(label, style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
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
          _sectionTitle('05', 'Amenidades y características', icon: Icons.stars_outlined),
          const SizedBox(height: 16),

          const Text(
            'Amenidades del edificio',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 12),

          if (property.amenities.isEmpty)
            const Text(
              'No se especificaron amenidades.',
              style: TextStyle(fontSize: 13, color: KazaTheme.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 16,
              children: property.amenities.map((amenity) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 3,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: KazaTheme.azulKaza.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getIconForAmenity(amenity), size: 24, color: KazaTheme.azulKaza),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        amenity,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: KazaTheme.textSecondary, fontWeight: FontWeight.w600),
                        maxLines: 2,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          _divider(),

          const Text(
            'Características del edificio',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),

          _detailRow(Icons.business, 'Torre', '${property.floorsTotal} pisos'),
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
          _sectionTitle('06', 'Disponibilidad y frescura', icon: Icons.update_outlined),
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

          // Fechas
          _detailRow(Icons.calendar_today_outlined, 'Publicación activa desde', '05 abr. 2025'),
          const SizedBox(height: 4),

          // Frescura row
          Row(
            children: [
              const Icon(Icons.refresh, size: 18, color: KazaTheme.grisMedio),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Frescura (actualización de info)', style: TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KazaTheme.verdeEntorno.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Actualizada', style: TextStyle(fontSize: 11, color: KazaTheme.verdeEntorno, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _detailRow(Icons.event_note_outlined, 'Última actualización', '12 may. 2025'),
          _detailRow(Icons.sync_outlined, 'Frecuencia de actualización', 'Quincenal'),

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
                    'La información puede cambiar. Verifica siempre la fecha de actualización.',
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
  const PropertyLocationSection({super.key});

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
          _sectionTitle('07', 'Ubicación y entorno', icon: Icons.map_outlined),
          const SizedBox(height: 16),

          const Text(
            'Ubicación',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_pin, size: 16, color: KazaTheme.primaryCoral),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Calle 5 Norte, Equipetrol Norte, Santa Cruz, Bolivia',
                  style: TextStyle(fontSize: 13, color: KazaTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini mapa placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              width: double.infinity,
              color: const Color(0xFFE8F0E9),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Simulated map grid
                  CustomPaint(
                    size: const Size(double.infinity, 160),
                    painter: _MapGridPainter(),
                  ),
                  // Pin
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: KazaTheme.primaryCoral,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: KazaTheme.primaryCoral.withValues(alpha: 0.4), blurRadius: 8)],
                        ),
                        child: const Text('Equipetrol Norte', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      CustomPaint(
                        size: const Size(16, 8),
                        painter: _TrianglePainter(),
                      ),
                    ],
                  ),
                  // Map/Satellite toggle
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _mapToggle('Mapa', true),
                          _mapToggle('Satélite', false),
                        ],
                      ),
                    ),
                  ),
                  // Ver en mapa
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
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

          _divider(),

          const Text(
            'Entorno',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),

          ..._distances.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: KazaTheme.grisClaro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(d['icon'] as IconData, size: 16, color: KazaTheme.azulKaza),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(d['place'] as String, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
                  ),
                  Text(
                    d['dist'] as String,
                    style: const TextStyle(fontSize: 12, color: KazaTheme.azulKaza, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    d['km'] as String,
                    style: const TextStyle(fontSize: 12, color: KazaTheme.grisMedio),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),
          GestureDetector(
            child: const Row(
              children: [
                Icon(Icons.arrow_forward_ios, size: 12, color: KazaTheme.primaryCoral),
                SizedBox(width: 4),
                Text('Ver más del entorno', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.primaryCoral)),
              ],
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
          _sectionTitle('08', 'Anunciante / Publicador', icon: Icons.store_mall_directory_outlined),
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
          const Text(
            'Sobre el anunciante',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 8),
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
    return Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
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

          const Text(
            'Documentos',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),

          ..._docs.map(
            (d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KazaTheme.grisClaro,
                borderRadius: BorderRadius.circular(10),
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

          const Text(
            'Información legal',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),

          _legalRow('Título de propiedad', 'Verificado', isVerified: true),
          _legalRow('Uso de suelo', 'Residencial'),
          _legalRow('Reglamento de copropiedad', 'Disponible'),
          _legalRow('Impuestos al día', 'Verificado', isVerified: true),

          _divider(),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KazaTheme.grisClaro,
              borderRadius: BorderRadius.circular(8),
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
          _sectionTitle('10', 'Guardar, comparar y compartir', icon: Icons.bookmark_border_outlined),
          const SizedBox(height: 16),

          const Text(
            'Acciones rápidas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 12),

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

          const Text(
            'Comparar con otras',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 10),

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
            color: KazaTheme.grisClaro,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
        border: Border.all(color: selected ? KazaTheme.azulKaza.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
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
          const Text(
            'Agendar visita',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
          ),
          const SizedBox(height: 8),
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
                _sectionTitle('12', 'Reportar publicación', icon: Icons.flag_outlined),
                const Spacer(),
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
              const Text(
                'Motivo del reporte',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
              ),
              const SizedBox(height: 10),

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
              const Text(
                'Comentarios adicionales (opcional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KazaTheme.azulKaza),
              ),
              const SizedBox(height: 8),
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
