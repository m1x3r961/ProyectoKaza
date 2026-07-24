/// Categorías de veracidad exigidas por Kaza Master v0.2
enum KazaMediaType {
  realPhoto,
  editedPhoto,
  render,
  aiConcept,
  virtualStaging,
  video,
  drone,
  tour360,
  plan,
  constructionProgress,
}

extension KazaMediaTypeExtension on KazaMediaType {
  String get label {
    switch (this) {
      case KazaMediaType.realPhoto:
        return 'Foto Real (Sin manipulación)';
      case KazaMediaType.editedPhoto:
        return 'Foto Editada (Iluminación/Retoque)';
      case KazaMediaType.render:
        return 'Render 3D / Arquitectónico';
      case KazaMediaType.aiConcept:
        return 'Concepto IA (Imagina)';
      case KazaMediaType.virtualStaging:
        return 'Amueblamiento Virtual';
      case KazaMediaType.video:
        return 'Video Recorrido';
      case KazaMediaType.drone:
        return 'Toma Aérea con Dron';
      case KazaMediaType.tour360:
        return 'Tour Virtual 360°';
      case KazaMediaType.plan:
        return 'Plano Comercial 2D/3D';
      case KazaMediaType.constructionProgress:
        return 'Avance de Obra (Preventa)';
    }
  }

  String get dbValue {
    switch (this) {
      case KazaMediaType.realPhoto:
        return 'REAL_PHOTO';
      case KazaMediaType.editedPhoto:
        return 'EDITED_PHOTO';
      case KazaMediaType.render:
        return 'RENDER';
      case KazaMediaType.aiConcept:
        return 'AI_CONCEPT';
      case KazaMediaType.virtualStaging:
        return 'VIRTUAL_STAGING';
      case KazaMediaType.video:
        return 'VIDEO';
      case KazaMediaType.drone:
        return 'DRONE';
      case KazaMediaType.tour360:
        return '360';
      case KazaMediaType.plan:
        return 'PLAN';
      case KazaMediaType.constructionProgress:
        return 'CONSTRUCTION_PROGRESS';
    }
  }
}

class KazaMediaItem {
  final String id;
  final String url;
  final String? path;
  final KazaMediaType mediaType;
  final bool isThumbnail;

  KazaMediaItem({
    required this.id,
    required this.url,
    this.path,
    this.mediaType = KazaMediaType.realPhoto,
    this.isThumbnail = false,
  });

  KazaMediaItem copyWith({
    String? id,
    String? url,
    String? path,
    KazaMediaType? mediaType,
    bool? isThumbnail,
  }) {
    return KazaMediaItem(
      id: id ?? this.id,
      url: url ?? this.url,
      path: path ?? this.path,
      mediaType: mediaType ?? this.mediaType,
      isThumbnail: isThumbnail ?? this.isThumbnail,
    );
  }
}
