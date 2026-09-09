import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_config.dart';
import '../../profile/models/listing_model.dart';
import 'organizations_provider.dart';

final crmPropertiesProvider = FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  final orgsState = ref.watch(organizationsProvider);
  if (orgsState.myOrgs.isEmpty) return [];

  final orgId = orgsState.myOrgs.first.id;

  try {
    final response = await SupabaseConfig.client
        .from('properties')
        .select('*')
        .eq('organization_id', orgId)
        .order('created_at', ascending: false);

    final List<ListingModel> listings = (response as List<dynamic>)
        .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return listings;
  } catch (e) {
    throw Exception('Error al cargar propiedades de la organización: $e');
  }
});
