// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _intentKey = 'kaza_auth_intent';

/// Drops `?error=...` left by a failed Supabase OAuth redirect, keeping the
/// current hash route, without reloading the page.
void clearAuthErrorFromUrl() {
  final location = html.window.location;
  html.window.history.replaceState(null, '', '${location.pathname}${location.hash}');
}

/// Remembers whether the user chose "login" or "signup"; survives the
/// full-page OAuth redirect within the same tab.
void saveAuthIntent(String intent) {
  try {
    html.window.sessionStorage[_intentKey] = intent;
  } catch (_) {}
}

/// Returns and forgets the intent saved before OAuth.
String? takeAuthIntent() {
  try {
    return html.window.sessionStorage.remove(_intentKey);
  } catch (_) {
    return null;
  }
}
