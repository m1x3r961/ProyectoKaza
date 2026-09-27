import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/listing_model.dart';

final myListingsProvider =
    StateNotifierProvider<MyListingsNotifier, AsyncValue<List<ListingModel>>>(
        (ref) {
  final authState = ref.watch(kazaAuthProvider);
  return MyListingsNotifier(
    userId: authState.userId,
    supabase: Supabase.instance.client,
  );
});

class MyListingsNotifier extends StateNotifier<AsyncValue<List<ListingModel>>> {
  final String? userId;
  final SupabaseClient supabase;

  MyListingsNotifier({required this.userId, required this.supabase})
      : super(const AsyncValue.loading()) {
    if (userId != null) {
      _fetchListings();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _fetchListings() async {
    try {
      state = const AsyncValue.loading();

      // Select listings where owner_id == current user
      final response = await ApiClient().request('/api/listings/mine');
      final List<ListingModel> listings = (response as List<dynamic>)
          .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (mounted) state = AsyncValue.data(listings);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String listingId, String newStatus) async {
    final listing = state.value!.firstWhere((l) => l.id == listingId);
    await ApiClient()
        .request('/api/listings/$listingId/status', method: 'PATCH', body: {
      'status': newStatus == 'PUBLISHED' ? 'AVAILABLE' : newStatus,
      'version': listing.version
    });
    await _fetchListings();
  }

  Future<void> refreshAvailability(String listingId) async {
    await ApiClient()
        .request('/api/listings/$listingId/refresh', method: 'POST');
    await _fetchListings();
  }
}
