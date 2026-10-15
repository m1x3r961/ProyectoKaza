/// Non-web platforms never receive OAuth errors in the page URL.
void clearAuthErrorFromUrl() {}

// Native OAuth returns to the same running app, so memory is enough.
String? _intent;

/// Remembers whether the user chose "login" or "signup" before OAuth.
void saveAuthIntent(String intent) => _intent = intent;

/// Returns and forgets the intent saved before OAuth.
String? takeAuthIntent() {
  final value = _intent;
  _intent = null;
  return value;
}
