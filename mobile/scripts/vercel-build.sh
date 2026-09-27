#!/usr/bin/env bash
set -euo pipefail

# Public build configuration only. Never inject service_role or provider secrets.
: "${SUPABASE_URL:?Define SUPABASE_URL in this Vercel project}"
: "${SUPABASE_ANON_KEY:?Define SUPABASE_ANON_KEY in this Vercel project}"
: "${API_BASE_URL:?Define API_BASE_URL with the deployed backend URL}"
KAZA_APP_ENV="${APP_ENV:-production}"
KAZA_FLUTTER_VERSION="3.27.0"
KAZA_FLUTTER_DIR="$PWD/.vercel/flutter-sdk"
if [[ ! -x "$KAZA_FLUTTER_DIR/bin/flutter" ]]; then
  mkdir -p "$PWD/.vercel"
  git clone --depth 1 --branch "$KAZA_FLUTTER_VERSION" https://github.com/flutter/flutter.git "$KAZA_FLUTTER_DIR"
fi
export PATH="$KAZA_FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics
flutter pub get --enforce-lockfile
flutter build web --release \
  --dart-define="APP_ENV=$KAZA_APP_ENV" \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
  --dart-define="API_BASE_URL=$API_BASE_URL"
