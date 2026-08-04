import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

bool _registered = false;

Widget buildPlatformVideoLogo({required double width, required double height, required BoxFit fit}) {
  final viewId = 'kaza-video-logo';
  if (!_registered) {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final video = html.VideoElement()
        ..src = 'assets/assets/images/kaza.mp4'
        ..autoplay = true
        ..loop = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = fit == BoxFit.cover ? 'cover' : 'contain';
      return video;
    });
    _registered = true;
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewId),
  );
}
