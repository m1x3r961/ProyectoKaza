import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../providers/map_properties_provider.dart';

/// 📋 MAP LIST TOGGLE — "07 TOGGLE LISTA"
/// Overlay list view that shows properties in a scrollable list
/// tied to the current map viewport. Can be toggled on/off.
class MapListOverlay extends StatelessWidget {
  final List<PropertyMapItem> properties;
  final VoidCallback onClose;
  final ValueChanged<PropertyMapItem> onPropertyTap;
  final ValueChanged<PropertyMapItem> onFavoriteTap;

  const MapListOverlay({
    super.key,
    required this.properties,
    required this.onClose,
    required this.onPropertyTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${properties.length} propiedades',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: KazaTheme.azulKaza,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: KazaTheme.n000,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Ordenar',
                            style: TextStyle(
                              color: KazaTheme.azulKaza,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: KazaTheme.azulKaza),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(Icons.close, color: KazaTheme.grisMedio, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // List
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: properties.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (context, index) {
                final prop = properties[index];
                return _PropertyListItem(
                  property: prop,
                  onTap: () => onPropertyTap(prop),
                  onFavoriteTap: () => onFavoriteTap(prop),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyListItem extends StatelessWidget {
  final PropertyMapItem property;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _PropertyListItem({
    required this.property,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: property.imageUrl != null
                  ? Image.network(
                      property.imageUrl!,
                      width: 80,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KazaTheme.azulKaza,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (property.address != null)
                    Text(
                      property.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KazaTheme.grisMedio,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Consultar precio',
                    style: TextStyle(
                      color: KazaTheme.azulKaza,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Favorite
            GestureDetector(
              onTap: onFavoriteTap,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: KazaTheme.grisMedio,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.home_work_rounded, color: Colors.black12, size: 28),
    );
  }
}
