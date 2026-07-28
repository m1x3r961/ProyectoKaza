import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/listing_model.dart';

final myListingsProvider = StateNotifierProvider<MyListingsNotifier, AsyncValue<List<ListingModel>>>((ref) {
  final authState = ref.watch(kazaAuthProvider);
  return MyListingsNotifier(
    userId: authState.userId,
    supabase: Supabase.instance.client,
  );
});

class MyListingsNotifier extends StateNotifier<AsyncValue<List<ListingModel>>> {
  final String? userId;
  final SupabaseClient supabase;

  MyListingsNotifier({required this.userId, required this.supabase}) : super(const AsyncValue.loading()) {
    if (userId != null) {
      _fetchListings();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _fetchListings() async {
    try {
      state = const AsyncValue.loading();
      
      // Select listings where operator_user_id == current user
      final response = await supabase
          .from('listings')
          .select('*')
          .eq('operator_user_id', userId as Object)
          .order('created_at', ascending: false);
          
      final List<ListingModel> listings = (response as List<dynamic>)
          .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
          .toList();
          
      state = AsyncValue.data(listings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String listingId, String newStatus) async {
    try {
      // Optimistic update
      final previousState = state;
      if (state.hasValue) {
        final updatedList = state.value!.map((l) {
          if (l.id == listingId) {
            return ListingModel(
              id: l.id,
              title: l.title,
              description: l.description,
              priceOriginal: l.priceOriginal,
              currencyOriginal: l.currencyOriginal,
              status: newStatus,
              freshnessConfirmedAt: l.freshnessConfirmedAt,
            );
          }
          return l;
        }).toList();
        state = AsyncValue.data(updatedList);
      }

      await supabase
          .from('listings')
          .update({'status': newStatus})
          .eq('id', listingId);
          
    } catch (e) {
      // Revert if error
      _fetchListings();
      rethrow;
    }
  }

  Future<void> refreshAvailability(String listingId) async {
    try {
      // Update freshness to NOW()
      await supabase
          .from('listings')
          .update({'freshness_confirmed_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', listingId);
          
      // Refetch to get the latest dates
      await _fetchListings();
    } catch (e) {
      rethrow;
    }
  }
}
