import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/kaza_media_item.dart';

/// 📸 KAZA MEDIA PICKER WIDGET - Carga de fotos con etiquetado de veracidad
class MediaPickerWidget extends StatefulWidget {
  final List<KazaMediaItem> initialItems;
  final ValueChanged<List<KazaMediaItem>> onChanged;

  const MediaPickerWidget({
    super.key,
    required this.initialItems,
    required this.onChanged,
  });

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  late List<KazaMediaItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  void _addDemoMediaItem() {
    final newItem = KazaMediaItem(
      id: 'img-${DateTime.now().millisecondsSinceEpoch}',
      url: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600',
      mediaType: KazaMediaType.realPhoto,
      isThumbnail: _items.isEmpty,
    );

    setState(() {
      _items.add(newItem);
    });
    widget.onChanged(_items);
  }

  void _updateMediaType(int index, KazaMediaType newType) {
    setState(() {
      _items[index] = _items[index].copyWith(mediaType: newType);
    });
    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Galería Multimedial & Veracidad',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Añadir Foto/Render', style: TextStyle(fontSize: 12)),
              onPressed: _addDemoMediaItem,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'En Kaza debes clasificar honestamente el tipo de contenido. Un render o concepto IA no puede llamarse "Foto Real".',
          style: TextStyle(color: KazaTheme.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 12),

        if (_items.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: KazaTheme.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KazaTheme.glassBorder, style: BorderStyle.solid),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 36, color: KazaTheme.textMuted),
                SizedBox(height: 8),
                Text('No hay imágenes agregadas aún', style: TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.url,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.broken_image, size: 20, color: Colors.white38),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButton<KazaMediaType>(
                              isExpanded: true,
                              value: item.mediaType,
                              underline: const SizedBox(),
                              items: KazaMediaType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.label,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _updateMediaType(index, val);
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _removeItem(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
