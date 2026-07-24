import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración de cliente Supabase para Kaza
class SupabaseConfig {
  // URL del proyecto obtenido de Supabase Dashboard
  static const String supabaseUrl = 'https://mgzbfklvtxprqofiaivl.supabase.co';

  // ⚠️ REEMPLAZAR con la clave 'anon' 'public' obtenida en:
  // Settings (⚙️) -> API -> Project API keys -> anon (public)
  static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY_AQUI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
