import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/ride_category.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/usecases/passenger/calculate_ride_category_prices.dart';
import '../../../../domain/usecases/usecase.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import 'active_ride_provider.dart';
import 'booking_dependencies.dart';
import 'booking_route_refresh_provider.dart';

part 'ride_categories_provider.g.dart';

final _log = AppLogger.instance;
const pricingUnavailableMessage =
    'Impossible de calculer le prix pour le moment. Veuillez réessayer plus tard.';
final categoryAutoSelectionEnabledProvider = StateProvider<bool>((_) => true);
final lastSelectedCategoryIdProvider = StateProvider<String?>((_) => null);
final ridePriceAutoRefreshInProgressProvider = StateProvider<bool>(
  (_) => false,
);
final lastPricedRideCategoriesProvider = StateProvider<List<RideCategory>?>(
  (_) => null,
);
final allowBaseCategoriesForUnpricedDestinationProvider = StateProvider<bool>(
  (_) => false,
);

@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  RideCategory? build() {
    final autoSelectionEnabled = ref.watch(
      categoryAutoSelectionEnabledProvider,
    );
    final categoriesAsync = ref.watch(rideCategoriesProvider);
    final categories = categoriesAsync.value;
    if (!autoSelectionEnabled || categories == null || categories.isEmpty) {
      return null;
    }

    final lastSelectedCategoryId = ref.watch(lastSelectedCategoryIdProvider);
    if (lastSelectedCategoryId != null) {
      for (final category in categories) {
        if (category.id == lastSelectedCategoryId) return category;
      }
    }

    return categories.firstWhere(
      (category) => category.id == 'MAGIC',
      orElse: () => categories.first,
    );
  }

  void select(RideCategory category) {
    ref.read(categoryAutoSelectionEnabledProvider.notifier).state = true;
    ref.read(lastSelectedCategoryIdProvider.notifier).state = category.id;
    state = category;
  }

  void clear() {
    ref.read(categoryAutoSelectionEnabledProvider.notifier).state = true;
    ref.read(lastSelectedCategoryIdProvider.notifier).state = null;
    state = null;
  }

  void requireManualSelection() {
    ref.read(categoryAutoSelectionEnabledProvider.notifier).state = false;
    ref.read(lastSelectedCategoryIdProvider.notifier).state = null;
    state = null;
  }
}

@riverpod
Future<List<RideCategory>> rideCategories(Ref ref) async {
  ref.watch(bookingManualRefreshTriggerProvider);
  final isAutoRefresh = ref.read(ridePriceAutoRefreshInProgressProvider);
  final getRideCategories = ref.read(getRideCategoriesUseCaseProvider);
  final calculatePrices = ref.read(calculateRideCategoryPricesUseCaseProvider);
  final baseCategoriesResult = await getRideCategories(const NoParams());
  final baseCategories = baseCategoriesResult.getOrElse(() => []);

  final destination = ref.watch(selectedDestinationProvider);
  if (destination == null || !destination.hasValidCoordinates) {
    return baseCategories;
  }
  if (!_isBackendPricingPlaceId(destination.placeId)) {
    if (isAutoRefresh) return _cachedPricedCategoriesOrEmpty(ref);
    final hasActiveRide = ref.read(activeRideControllerProvider) != null;
    if (!hasActiveRide) {
      _publishPricingError(ref);
    }
    _log.warning(
      'Pricing skipped: destination placeId is not backend-compatible.',
    );
    final allowBaseCategories = ref.watch(
      allowBaseCategoriesForUnpricedDestinationProvider,
    );
    return allowBaseCategories ? baseCategories : const [];
  }

  // Résoudre les coordonnées d'origine indépendamment des directions.
  final originCoords = await _resolveOriginCoords(ref);
  if (originCoords == null) {
    if (isAutoRefresh) return _cachedPricedCategoriesOrEmpty(ref);
    _publishPricingError(ref);
    _log.warning('Pricing skipped: origin coordinates unavailable.');
    return const [];
  }

  // Note : on ne watch PAS routeDirectionsProvider ici.
  // Les directions sont gérées séparément dans route_preview_screen.
  // Le pricing backend n'a besoin que des coordonnées + placeId.

  final pricedResult = await calculatePrices(
    CalculateRideCategoryPricesParams(
      baseCategories: baseCategories,
      latDeparture: originCoords.$1,
      longDeparture: originCoords.$2,
      arrivalPlaceId: destination.placeId,
      arrivalLat: destination.latitude,
      arrivalLong: destination.longitude,
    ),
  );
  return pricedResult.fold(
    (failure) {
      if (isAutoRefresh) return _cachedPricedCategoriesOrEmpty(ref);
      _publishPricingError(ref);
      _log.warning('Pricing failed: ${failure.message}');
      return const [];
    },
    (pricedCategories) {
      if (pricedCategories.isNotEmpty) {
        ref.read(lastPricedRideCategoriesProvider.notifier).state =
            pricedCategories;
      }
      return pricedCategories;
    },
  );
}

bool _isBackendPricingPlaceId(String placeId) {
  final value = placeId.trim();
  if (value.isEmpty) return false;
  return !value.startsWith('manual_') &&
      !value.startsWith('manual_map_') &&
      !value.startsWith('landmark_');
}

void _publishPricingError(Ref ref) {
  ref.read(bookingErrorProvider.notifier).state = pricingUnavailableMessage;
}

List<RideCategory> _cachedPricedCategoriesOrEmpty(Ref ref) {
  return ref.read(lastPricedRideCategoriesProvider) ?? const [];
}

/// Résout les coordonnées d'origine depuis les sources disponibles.
///
/// Ordre de priorité :
/// 1. Pickup manuel (si l'utilisateur a choisi un point de départ)
/// 2. Snapshot d'origine (capturé au début du flux de réservation)
/// 3. Position GPS actuelle (fallback)
Future<(double, double)?> _resolveOriginCoords(Ref ref) async {
  final manualPickup = ref.watch(selectedPickupProvider);
  if (manualPickup != null && manualPickup.hasValidCoordinates) {
    return (manualPickup.latitude, manualPickup.longitude);
  }

  final snapshot = ref.watch(bookingOriginSnapshotProvider);
  if (snapshot != null) {
    return (snapshot.latitude, snapshot.longitude);
  }

  final positionAsync = ref.watch(currentLocationProvider);
  final position =
      positionAsync.asData?.value ??
      await ref.watch(currentLocationProvider.future);
  if (position != null) {
    return (position.latitude, position.longitude);
  }

  return null;
}
