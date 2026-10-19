# Compilar y subir KAZA a App Store desde la Mac

Usa este mismo repositorio en la Mac. No copies solo `lib/`: la app también necesita `pubspec.yaml`, `assets/` y la configuración de `ios/`. La firma no depende del código sino del **Bundle ID** y del **Team** que elijas en Xcode.

## 1. Requisitos en la Mac

- Xcode actualizado, con tu cuenta de Apple Developer agregada en Xcode → Settings → Accounts.
- Flutter **3.27.0** (la misma versión que usa el proyecto): `flutter --version`.
- CocoaPods: `sudo gem install cocoapods` o `brew install cocoapods`.

## 2. Traer el proyecto

```sh
git clone https://github.com/m1x3r961/ProyectoKaza.git
cd ProyectoKaza/mobile
flutter pub get --enforce-lockfile
cd ios && pod install && cd ..
```

Si `pod install` dice que no hay Podfile, ejecuta primero `flutter build ios --config-only --release` (lo genera) y repite `pod install`.

## 3. Firma con la app de App Store Connect

1. Abre `mobile/ios/Runner.xcworkspace` (el `.xcworkspace`, no el `.xcodeproj`).
2. Selecciona el proyecto **Runner** → target **Runner** → pestaña **Signing & Capabilities**.
3. Activa **Automatically manage signing** y elige tu **Team**.
4. En **Bundle Identifier** pon exactamente el de tu app en App Store Connect
   (App Store Connect → tu app → Información de la app → ID del paquete).
   El proyecto trae `com.kaza.mobile`; cámbialo solo si tu app usa otro.

## 4. Número de versión

App Store Connect exige que cada subida tenga un número de compilación mayor que el anterior. Si ya subiste builds desde otro proyecto con esa app, usa un número mayor al último:

```sh
# ejemplo: versión 1.0.0, compilación 2
--build-name=1.0.0 --build-number=2
```

## 5. Compilar el paquete para App Store

Desde `ProyectoKaza/mobile`:

```sh
flutter build ipa --release \
  --build-name=1.0.0 --build-number=2 \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=https://mgzbfklvtxprqofiaivl.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_Hx6ofANMtz9ZIq8exX16xw_s0sVUHzc \
  --dart-define=API_BASE_URL=https://proyecto-kaza-backend.vercel.app
```

Son valores públicos (los mismos de la web y del APK). Nunca agregues aquí claves de servicio.

El resultado queda en `build/ios/ipa/`. Para subirlo:

- **Opción A:** abre `build/ios/archive/Runner.xcarchive` (doble clic) → Xcode Organizer → **Distribute App** → **App Store Connect** → **Upload**.
- **Opción B:** app **Transporter** de Apple → arrastra el `.ipa` de `build/ios/ipa/` → **Deliver**.

Después de unos minutos el build aparece en App Store Connect → TestFlight.

## 6. Probar en un iPhone antes de subir

Con el iPhone conectado por cable:

```sh
flutter run --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=https://mgzbfklvtxprqofiaivl.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_Hx6ofANMtz9ZIq8exX16xw_s0sVUHzc \
  --dart-define=API_BASE_URL=https://proyecto-kaza-backend.vercel.app
```

## Lo que ya está configurado en `ios/`

| Qué | Valor |
| --- | --- |
| Nombre visible | KAZA |
| Bundle ID por defecto | `com.kaza.mobile` |
| Íconos | Símbolo de KAZA sobre blanco, sin transparencia (requisito de Apple) |
| Login con Google | Esquema `com.kaza.mobile` → vuelve a la app por `com.kaza.mobile://login-callback/` (ya permitido en Supabase) |
| Permisos | Fotos y cámara, con su explicación en español (para subir fotos de propiedades y de perfil) |
| Cifrado | `ITSAppUsesNonExemptEncryption = NO` (solo HTTPS estándar), así App Store Connect no pregunta por exportación |
| Orientación | Vertical en iPhone; todas en iPad |

## Para la ficha de App Store

- URL de política de privacidad: `https://proyecto-kaza.vercel.app/privacidad.html`
- Apple exige que, si la app permite crear cuenta, también permita **eliminarla desde la app** (Guideline 5.1.1(v)).
