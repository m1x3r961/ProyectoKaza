// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Drops `?error=...` left by a failed Supabase OAuth redirect, keeping the
/// current hash route, without reloading the page.
void clearAuthErrorFromUrl() {
  final location = html.window.location;
  html.window.history.replaceState(null, '', '${location.pathname}${location.hash}');
}
