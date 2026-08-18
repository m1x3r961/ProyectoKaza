import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../providers/map_properties_provider.dart';
import 'property_detail_screen.dart';

/// 🏢 BUILDING STACK BOTTOM SHEET — "09 BUILDING STACK"
/// Shows building/cluster details with list of units.
/// Design: "Edificio en [address]" header, barrio, unit count,
/// list of units with ambientes + superficie + "Consultar precio"
class ClusterBottomSheet extends StatelessWidget {
  final PropertyMapItem clusterItem;

  const ClusterBottomSheet({super.key, required this.clusterItem});

  @override
  Widget build(BuildContext context) {
    final subItems = clusterItem.subItems ?? [];
    if (subItems.isEmpty) return const SizedBox.shrink();

    final address = subItems.first.address ?? 'Ubicación';
    final unitCount = subItems.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header — Building name & info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edificio en $address',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: KazaTheme.azulKaza,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subItems.first.type,
                            style: const TextStyle(
                              color: KazaTheme.grisMedio,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$unitCount unidades disponibles',
                            style: const TextStyle(
                              color: KazaTheme.azulKaza,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: KazaTheme.grisMedio),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Unit list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shrinkWrap: true,
              itemCount: subItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (context, index) {
                final item = subItems[index];
                return _BuildingUnitItem(
                  item: item,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: item)),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: KazaTheme.azulKaza,
                  side: const BorderSide(color: KazaTheme.azulKaza),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Could navigate to a full building page
                },
                child: Text(
                  'Ver todas las unidades ($unitCount)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single unit row in the building stack
class _BuildingUnitItem extends StatelessWidget {
  final PropertyMapItem item;
  final VoidCallback onTap;

  const _BuildingUnitItem({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Unit info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.bedrooms} ambientes · ${item.surface}',
                    style: const TextStyle(
                      color: KazaTheme.azulKaza,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Consultar precio',
                    style: TextStyle(
                      color: KazaTheme.grisMedio,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Favorite icon
            GestureDetector(
              child: const Padding(
                padding: EdgeInsets.all(4),
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
}
