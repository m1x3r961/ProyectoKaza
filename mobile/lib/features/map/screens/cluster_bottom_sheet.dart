import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../providers/map_properties_provider.dart';
import 'property_detail_screen.dart';

class ClusterBottomSheet extends StatelessWidget {
  final PropertyMapItem clusterItem;

  const ClusterBottomSheet({super.key, required this.clusterItem});

  @override
  Widget build(BuildContext context) {
    final subItems = clusterItem.subItems ?? [];
    if (subItems.isEmpty) return const SizedBox.shrink();

    final featured = subItems.first;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Property
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: featured)));
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: featured.imageUrl != null
                                ? Image.network(featured.imageUrl!, width: 120, height: 100, fit: BoxFit.cover)
                                : Container(
                                    width: 120,
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.home_work, color: Colors.grey, size: 40),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  featured.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.azulKaza),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  featured.price,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: KazaTheme.primaryCoralLight),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${featured.bedrooms} Dorm · ${featured.bathrooms} Baños · ${featured.surface}',
                                  style: const TextStyle(color: KazaTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KazaTheme.azulKaza,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Contactar', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KazaTheme.azulKaza,
                              side: const BorderSide(color: KazaTheme.azulKaza),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('WhatsApp', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Propiedades en este punto (${subItems.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KazaTheme.textPrimary),
                        ),
                        Text(
                          'Ver todas (${subItems.length}) >',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: KazaTheme.primaryCoralLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List of other properties
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: subItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 24, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final item = subItems[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: item)));
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.imageUrl != null
                                    ? Image.network(item.imageUrl!, width: 70, height: 60, fit: BoxFit.cover)
                                    : Container(
                                        width: 70,
                                        height: 60,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.home, color: Colors.grey),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.azulKaza),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.price,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: KazaTheme.primaryCoralLight),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
