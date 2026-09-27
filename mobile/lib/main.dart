import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes/app_router.dart';
import 'app/theme/kaza_theme.dart';
import 'core/network/supabase_config.dart';

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

  runApp(
    const ProviderScope(
      child: KazaApp(),
    ),
  );
}

class KazaApp extends StatelessWidget {
  const KazaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kaza · Product & Architecture System',
      debugShowCheckedModeBanner: false,
      theme: KazaTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) => SupabaseConfig.appEnv == 'demo'
          ? Banner(
              message: 'DEMO', location: BannerLocation.topEnd, child: child!)
          : child!,
    );
  }
}
