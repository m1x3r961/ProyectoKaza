import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes/app_router.dart';
import 'app/theme/kaza_theme.dart';
import 'core/network/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (SupabaseConfig.supabaseAnonKey != 'TU_SUPABASE_ANON_KEY_AQUI') {
      await SupabaseConfig.initialize();
    }
  } catch (e) {
    debugPrint('Supabase init notice: $e');
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
    );
  }
}
