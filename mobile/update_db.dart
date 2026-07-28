import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabaseUrl = 'https://mgzbfklvtxprqofiaivl.supabase.co';
  final supabaseAnonKey = 'sb_publishable_Hx6ofANMtz9ZIq8exX16xw_s0sVUHzc';
  
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  final client = Supabase.instance.client;
  
  try {
    await client.from('properties').update({'operation': 'VENTA'}).eq('operation', 'VENDER');
    print('DB updated');
  } catch (e) {
    print('Error: $e');
  }
}
