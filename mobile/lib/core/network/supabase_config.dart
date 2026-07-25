import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración de cliente Supabase para Kaza
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mgzbfklvtxprqofiaivl.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Hx6ofANMtz9ZIq8exX16xw_s0sVUHzc',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
