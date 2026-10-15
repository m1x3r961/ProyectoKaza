import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes/app_router.dart';
import 'app/theme/kaza_theme.dart';
import 'core/network/supabase_config.dart';
import 'core/utils/auth_url_cleanup_stub.dart'
    if (dart.library.html) 'core/utils/auth_url_cleanup_web.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    runApp(const MaterialApp(
        home: Scaffold(
            body: Center(
                child: Text(
                    'No se pudo iniciar KAZA. Revisa la configuración y la conexión.')))));
    return;
  }

  final authError = _takeAuthRedirectError();

  runApp(
    const ProviderScope(
      child: KazaApp(),
    ),
  );

  if (authError != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(authError),
        backgroundColor: KazaTheme.azulKaza,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ));
    });
  }
}

/// Reads and removes an OAuth error that Supabase appended to the URL.
String? _takeAuthRedirectError() {
  final params = Uri.base.queryParameters;
  if (!params.containsKey('error')) return null;
  clearAuthErrorFromUrl();
  final description = params['error_description'] ?? '';
  debugPrint('Auth redirect error: ${params['error']} · $description');
  if (description.contains('saving new user')) {
    return 'No pudimos crear tu cuenta. Intenta de nuevo en unos minutos o contacta a soporte.';
  }
  return 'No se pudo completar el inicio de sesión. Intenta de nuevo.';
}

class KazaApp extends StatelessWidget {
  const KazaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kaza · Product & Architecture System',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: KazaTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) => SupabaseConfig.appEnv == 'demo'
          ? Banner(
              message: 'DEMO', location: BannerLocation.topEnd, child: child!)
          : child!,
    );
  }
}
