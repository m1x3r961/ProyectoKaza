// ignore_for_file: avoid_web_libraries_in_flutter
import 'tour_platform_stub.dart' if (dart.library.html) 'tour_platform_web.dart'
    as tour_platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'tour_360_screen.dart';

/// Origen publico de la app web, donde vive `glb_viewer.html` (visor de modelos).
const _kWebOrigin = 'https://proyecto-kaza.vercel.app';

/// Un enlace directo a un `.glb` se descargaria en vez de verse: se abre en el visor.
String _resolveTourUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  if (!path.endsWith('.glb')) return url;
  final origin = kIsWeb ? Uri.base.origin : _kWebOrigin;
  return '$origin/glb_viewer.html?src=${Uri.encodeComponent(url)}';
}

/// Recorrido 3D a pantalla completa para el enlace que pegó el anunciante.
/// En web se embebe en un iframe; en nativo se abre en un WebView.
class Tour3DScreen extends StatelessWidget {
  final String url;
  final String title;

  const Tour3DScreen({super.key, required this.url, this.title = 'Recorrido 3D'});

  @override
  Widget build(BuildContext context) {
    final target = _resolveTourUrl(url);
    if (!kIsWeb) return Tour360Screen(url: target, title: title);

    final viewType = 'kaza-tour3d-${target.hashCode}';
    tour_platform.registerIframeView(viewType, target);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
      ),
      body: HtmlElementView(viewType: viewType),
    );
  }
}
