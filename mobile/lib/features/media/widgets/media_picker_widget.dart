import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/kaza_media_item.dart';

/// 📸 KAZA MEDIA PICKER WIDGET - Carga real de fotos con galería y miniaturas
/// Usa file_picker para Web + Mobile (galería) e image_picker para cámara (mobile)
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
  bool _isPickingImages = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  /// Seleccionar imágenes desde galería/archivos (funciona en Web y Mobile)
  Future<void> _pickImagesFromGallery() async {
    if (_isPickingImages) return;
    setState(() => _isPickingImages = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Necesario para obtener los bytes en Web
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.bytes != null) {
            final newItem = KazaMediaItem(
              id: 'img-${DateTime.now().millisecondsSinceEpoch}-${_items.length}',
              url: '',
              fileName: file.name,
              bytes: file.bytes,
              mediaType: KazaMediaType.realPhoto,
              isThumbnail: _items.isEmpty,
            );
            setState(() {
              _items.add(newItem);
            });
          }
        }
        widget.onChanged(_items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imágenes: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  /// Tomar foto con cámara (solo Mobile, en Web no aplica)
  Future<void> _takePhoto() async {
    if (_isPickingImages) return;
    setState(() => _isPickingImages = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final newItem = KazaMediaItem(
          id: 'img-${DateTime.now().millisecondsSinceEpoch}',
          url: '',
          fileName: pickedFile.name,
          bytes: bytes,
          mediaType: KazaMediaType.realPhoto,
          isThumbnail: _items.isEmpty,
        );
        setState(() {
          _items.add(newItem);
        });
        widget.onChanged(_items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agregar fotos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: KazaTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Selecciona de dónde quieres agregar tus imágenes', style: TextStyle(color: KazaTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: KazaTheme.azulKaza.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.photo_library, color: KazaTheme.azulKaza),
              ),
              title: const Text('Galería de fotos', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Selecciona una o varias imágenes', style: TextStyle(fontSize: 12, color: KazaTheme.textMuted)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImagesFromGallery();
              },
            ),
            // Solo mostrar opción de cámara en Mobile
            if (!kIsWeb) ...[
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: KazaTheme.primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: KazaTheme.primaryTeal),
                ),
                title: const Text('Tomar foto', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Usar la cámara del dispositivo', style: TextStyle(fontSize: 12, color: KazaTheme.textMuted)),
                onTap: () {
                  Navigator.pop(ctx);
                  _takePhoto();
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _updateMediaType(int index, KazaMediaType newType) {
    setState(() {
      _items[index] = _items[index].copyWith(mediaType: newType);
    });
    widget.onChanged(_items);
  }

  void _setAsThumbnail(int index) {
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(isThumbnail: i == index);
      }
    });
    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_items.isNotEmpty && !_items.any((e) => e.isThumbnail)) {
        _items[0] = _items[0].copyWith(isThumbnail: true);
      }
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isPickingImages
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_a_photo, size: 16),
              label: Text(_isPickingImages ? 'Cargando...' : 'Añadir Foto/Render', style: const TextStyle(fontSize: 12)),
              onPressed: _isPickingImages ? null : _showPickerOptions,
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
          GestureDetector(
            onTap: _showPickerOptions,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: KazaTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KazaTheme.glassBorder, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KazaTheme.primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: KazaTheme.primaryTeal),
                  ),
                  const SizedBox(height: 12),
                  const Text('Toca para agregar fotos', style: TextStyle(color: KazaTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(kIsWeb ? 'Seleccionar archivos' : 'Galería o Cámara', style: const TextStyle(color: KazaTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              // Thumbnail grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _items.length + 1,
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return GestureDetector(
                      onTap: _showPickerOptions,
                      child: Container(
                        decoration: BoxDecoration(
                          color: KazaTheme.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KazaTheme.glassBorder),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 32, color: KazaTheme.primaryTeal),
                            SizedBox(height: 4),
                            Text('Agregar', style: TextStyle(color: KazaTheme.primaryTeal, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }

                  final item = _items[index];
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showItemOptions(index),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: item.isThumbnail
                                ? Border.all(color: KazaTheme.primaryTeal, width: 2.5)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(item.isThumbnail ? 10 : 12),
                            child: _buildImageWidget(item),
                          ),
                        ),
                      ),
                      if (item.isThumbnail)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: KazaTheme.primaryTeal,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Portada', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _shortLabel(item.mediaType),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeItem(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${_items.length} ${_items.length == 1 ? 'imagen' : 'imágenes'} agregadas',
                style: const TextStyle(color: KazaTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageWidget(KazaMediaItem item) {
    if (item.bytes != null) {
      return Image.memory(
        item.bytes!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (item.url.isNotEmpty) {
      return Image.network(
        item.url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade800,
          child: const Icon(Icons.broken_image, size: 20, color: Colors.white38),
        ),
      );
    } else {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 32, color: Colors.grey),
      );
    }
  }

  String _shortLabel(KazaMediaType type) {
    switch (type) {
      case KazaMediaType.realPhoto: return 'REAL';
      case KazaMediaType.editedPhoto: return 'EDITADA';
      case KazaMediaType.render: return 'RENDER';
      case KazaMediaType.aiConcept: return 'IA';
      case KazaMediaType.virtualStaging: return 'VIRTUAL';
      case KazaMediaType.video: return 'VIDEO';
      case KazaMediaType.drone: return 'DRON';
      case KazaMediaType.tour360: return '360°';
      case KazaMediaType.plan: return 'PLANO';
      case KazaMediaType.constructionProgress: return 'OBRA';
    }
  }

  void _showItemOptions(int index) {
    final item = _items[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _buildImageWidget(item),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Clasificar tipo de contenido:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<KazaMediaType>(
              value: item.mediaType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: KazaMediaType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  _updateMediaType(index, val);
                  Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KazaTheme.primaryTeal,
                      side: const BorderSide(color: KazaTheme.primaryTeal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('Usar como portada', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      _setAsThumbnail(index);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _removeItem(index);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
