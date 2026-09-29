import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/models/favorite_place.dart';
import '../../core/models/places_models.dart';
import '../../core/models/ride_model.dart';
import '../../core/services/address_formatter_service.dart';
import '../../core/services/favorite_places_service.dart';
import '../../core/services/places_service.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_user_id.dart';
import '../../features/passenger/history/providers/history_provider.dart';
import 'places_provider.dart';

part 'favorite_places_provider.g.dart';

@riverpod
FavoritePlacesService favoritePlacesService(Ref ref) {
  final userData = ref.watch(passengerAuthProvider).userData;
  final userId = passengerAuthUserIdFromData(userData)?.toString() ?? 'guest';
  return FavoritePlacesService(userId: userId);
}

@riverpod
Future<List<FavoritePlace>> favoritePlacesList(Ref ref) async {
  return ref.read(favoritePlacesServiceProvider).getAll();
}

@riverpod
List<FavoritePlace> frequentDestinations(Ref ref) {
  const formatter = AddressFormatterService();
  final rides = ref.watch(rideHistoryProvider).asData?.value ?? [];

  final Map<String, List<Ride>> grouped = {};
  for (final ride in rides.where((r) => r.status == RideStatus.completed)) {
    final normalizedAddress = formatter.normalize(ride.arrivalAddress);
    grouped.update(
      normalizedAddress,
      (list) => [...list, ride],
      ifAbsent: () => [ride],
    );
  }

  return (grouped.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length)))
      .take(5)
      .map((entry) {
        final ride = entry.value.first;
        final normalizedAddress = formatter.normalize(ride.arrivalAddress);
        return FavoritePlace(
          id: 'freq_${normalizedAddress.hashCode}',
          name: formatter.primaryLabel(
            normalizedAddress,
            fallback: 'Destination',
          ),
          address: normalizedAddress,
          latitude: ride.arrivalLat,
          longitude: ride.arrivalLng,
          savedAt: ride.date,
        );
      })
      .toList();
}

@riverpod
class FavoritePlacesNotifier extends _$FavoritePlacesNotifier {
  @override
  void build() {}

  Future<void> save(FavoritePlace place) async {
    await ref.read(favoritePlacesServiceProvider).save(place);
    ref.invalidate(favoritePlacesListProvider);
  }

  Future<void> remove(String id) async {
    await ref.read(favoritePlacesServiceProvider).remove(id);
    ref.invalidate(favoritePlacesListProvider);
  }

  Future<void> navigateTo(BuildContext context, FavoritePlace favorite) async {
    final service = ref.read(placesServiceProvider);
    PlaceDetails? details;

    if (favorite.placeId != null && favorite.placeId!.isNotEmpty) {
      // Le favori a un vrai Google placeId
      if (!favorite.hasCoordinates) {
        details = await service.getPlaceDetails(favorite.placeId!);
      } else {
        details = PlaceDetails(
          placeId: favorite.placeId!,
          name: favorite.name,
          address: favorite.address,
          latitude: favorite.latitude!,
          longitude: favorite.longitude!,
        );
      }
    } else if (favorite.hasCoordinates) {
      // Pas de placeId : résoudre via Google Nearby Search
      details = await _resolveFromCoordinates(service, favorite);
    }

    if (details == null || !context.mounted) return;

    // Fermer la vue actuelle (modal ou écran favoris) avant de setter la destination,
    // pour que PassengerHomeScreen soit actif quand son listener déclenche la navigation.
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Le ref.listen de PassengerHomeScreen gère la navigation vers vehicleSelection.
    ref.read(selectedDestinationProvider.notifier).setPlace(details);
  }

  /// Résout un vrai Google placeId à partir des coordonnées du favori.
  Future<PlaceDetails?> _resolveFromCoordinates(
    PlacesService service,
    FavoritePlace favorite,
  ) async {
    // Chercher les lieux proches des coordonnées du favori
    final nearby = await service.getNearbyPlaces(
      lat: favorite.latitude!,
      lng: favorite.longitude!,
      radius: 100,
    );

    if (nearby.isNotEmpty) {
      // Prendre le lieu le plus proche qui a un vrai placeId
      final best = nearby.first;
      return PlaceDetails(
        placeId: best.placeId,
        name: favorite.name,
        address: favorite.address,
        latitude: favorite.latitude!,
        longitude: favorite.longitude!,
      );
    }

    // Fallback : chercher par nom pour obtenir un placeId valide
    final suggestions = await service.getAutocompleteSuggestions(favorite.name);
    if (suggestions.isNotEmpty) {
      return await service.getPlaceDetails(suggestions.first.placeId);
    }

    return null;
  }
}
