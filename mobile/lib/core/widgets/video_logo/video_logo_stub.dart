import 'package:flutter/material.dart';

Widget buildPlatformVideoLogo({required double width, required double height, required BoxFit fit}) {
  return Image.asset('assets/images/kaza_logo.gif', width: width, height: height, fit: fit, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
}
