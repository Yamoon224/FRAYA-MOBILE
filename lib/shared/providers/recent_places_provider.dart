import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/models/places_models.dart';
import '../../core/services/recent_places_service.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_user_id.dart';

part 'recent_places_provider.g.dart';

@riverpod
RecentPlacesService recentPlacesService(Ref ref) {
  final userData = ref.watch(passengerAuthProvider).userData;
  final userId = passengerAuthUserIdFromData(userData)?.toString() ?? 'guest';
  return RecentPlacesService(userId);
}

/// Provider des lieux récents — lit depuis SharedPreferences.
/// keepAlive: false → se recharge à chaque ouverture du sheet.
@riverpod
Future<List<PlaceDetails>> recentPlacesList(Ref ref) async {
  final service = ref.read(recentPlacesServiceProvider);
  return service.getAll();
}

/// Notifier pour ajouter/supprimer des lieux récents et invalider le cache.
@riverpod
class RecentPlacesNotifier extends _$RecentPlacesNotifier {
  @override
  void build() {}

  Future<void> add(PlaceDetails place) async {
    final service = ref.read(recentPlacesServiceProvider);
    await service.add(place);
    // Invalider le provider pour forcer le rechargement
    ref.invalidate(recentPlacesListProvider);
  }

  Future<void> remove(String placeId) async {
    final service = ref.read(recentPlacesServiceProvider);
    await service.remove(placeId);
    ref.invalidate(recentPlacesListProvider);
  }

  Future<void> clearAll() async {
    final service = ref.read(recentPlacesServiceProvider);
    await service.clearAll();
    ref.invalidate(recentPlacesListProvider);
  }
}
