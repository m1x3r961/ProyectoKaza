// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';

void registerTourIframe() {
  ui_web.platformViewRegistry.registerViewFactory(
      'kaza-pannellum-360',
      (int viewId) => html.IFrameElement()
        ..src = 'pannellum_360.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..setAttribute('allow', 'fullscreen; gyroscope; accelerometer'));
}

void setTourImages(List<String> images) {
  html.window.localStorage['kaza_360_images'] = jsonEncode(images);
}
