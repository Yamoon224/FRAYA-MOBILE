import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/core/utils/logger.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/calculate_ride_category_prices.dart';
import 'package:fraya_mobile/domain/usecases/passenger/get_ride_categories.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_route_refresh_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

void main() {
  AppConfig.instance.init(flavor: AppFlavor.dev);
  AppLogger.instance.init();

  test(
    'rideCategories computes priced categories using origin snapshot',
    () async {
      final repository = _FakeBookingRepository();
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_destination_1',
              name: 'Aeroport',
              address: 'Aeroport Felix Houphouet Boigny',
              latitude: 5.2612,
              longitude: -3.9262,
            ),
          );
      container
          .read(bookingOriginSnapshotProvider.notifier)
          .state = BookingOriginSnapshot(
        latitude: 5.348,
        longitude: -4.0135,
        capturedAt: DateTime(2026, 5, 20),
      );

      final firstResult = await _readRideCategories(container);

      expect(firstResult.firstWhere((c) => c.id == 'MAGIC').price, 3100);
      expect(
        firstResult.firstWhere((c) => c.id == 'MAGIC').amountReceived,
        2800,
      );
      expect(repository.calculateCalls, greaterThan(0));
    },
  );

  test(
    'rideCategories blocks pricing when destination placeId is empty',
    () async {
      final repository = _FakeBookingRepository();
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: '',
              name: 'Destination manuelle',
              address: 'Destination manuelle',
              latitude: 5.30,
              longitude: -4.01,
            ),
          );

      final result = await _readRideCategories(container);

      expect(result, isEmpty);
      expect(repository.calculateCalls, 0);
      expect(container.read(selectedCategoryProvider), isNull);
      expect(container.read(bookingErrorProvider), pricingUnavailableMessage);
    },
  );

  test(
    'rideCategories blocks pricing when destination placeId is local',
    () async {
      for (final placeId in ['manual_1', 'manual_map_1', 'landmark_1']) {
        final repository = _FakeBookingRepository();
        final container = ProviderContainer(
          overrides: [
            currentLocationProvider.overrideWith((ref) => const Stream.empty()),
            getRideCategoriesUseCaseProvider.overrideWithValue(
              GetRideCategoriesUseCase(repository),
            ),
            calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
              CalculateRideCategoryPricesUseCase(repository),
            ),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(selectedDestinationProvider.notifier)
            .setPlace(
              PlaceDetails(
                placeId: placeId,
                name: 'Destination locale',
                address: 'Destination locale',
                latitude: 5.30,
                longitude: -4.01,
              ),
            );

        final result = await _readRideCategories(container);

        expect(result, isEmpty);
        expect(repository.calculateCalls, 0);
        expect(container.read(selectedCategoryProvider), isNull);
        expect(container.read(bookingErrorProvider), pricingUnavailableMessage);
      }
    },
  );

  test(
    'rideCategories uses manual pickup origin before GPS fallback',
    () async {
      final repository = _FakeBookingRepository();
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(selectedPickupProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'manual_pickup_1',
              name: 'Pickup manuel',
              address: 'Pickup manuel',
              latitude: 5.3901,
              longitude: -4.0502,
            ),
          );
      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_destination_2',
              name: 'Yopougon',
              address: 'Yopougon',
              latitude: 5.3374,
              longitude: -4.0876,
            ),
          );

      final result = await container
          .read(rideCategoriesProvider.future)
          .timeout(const Duration(seconds: 1));

      expect(result, isNotEmpty);
      expect(repository.calculateCalls, greaterThan(0));
      expect(repository.lastBatchPricingParams, isNotNull);
      expect(repository.lastBatchPricingParams!.latDeparture, 5.3901);
      expect(repository.lastBatchPricingParams!.longDeparture, -4.0502);
    },
  );

  test(
    'rideCategories keeps missing destination placeId silent during active ride restoration',
    () async {
      final repository = _FakeBookingRepository();
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(activeRideControllerProvider.notifier)
          .initialize(
            const ActiveRide(
              rideId: 'ride_1',
              driverName: 'Chauffeur',
              driverPhoto: 'assets/images/driver_placeholder.png',
              driverRating: 4.8,
              carModel: 'Toyota',
              carPlate: 'AA-001-AA',
              driverLocation: LatLng(5.35, -4.01),
              status: RideStatus.accepted,
              estimatedPrice: 3000,
            ),
          );
      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: '',
              name: 'Destination restauree',
              address: 'Destination restauree',
              latitude: 5.30,
              longitude: -4.01,
            ),
          );
      container.read(bookingManualRefreshTriggerProvider.notifier).state = 1;

      final result = await _readRideCategories(container);

      expect(result, isEmpty);
      expect(repository.calculateCalls, 0);
      expect(container.read(bookingErrorProvider), isNull);
    },
  );

  test(
    'rideCategories does not fallback to base categories when pricing fails',
    () async {
      final repository = _FakeBookingRepository()
        ..calculateError = Exception('backend unavailable');
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_destination_3',
              name: 'Plateau',
              address: 'Plateau',
              latitude: 5.3245,
              longitude: -4.0201,
            ),
          );
      container
          .read(bookingOriginSnapshotProvider.notifier)
          .state = BookingOriginSnapshot(
        latitude: 5.348,
        longitude: -4.0135,
        capturedAt: DateTime(2026, 5, 20),
      );

      final result = await _readRideCategories(container);

      expect(result, isEmpty);
      expect(repository.calculateCalls, 1);
      expect(container.read(selectedCategoryProvider), isNull);
      expect(container.read(bookingErrorProvider), pricingUnavailableMessage);
    },
  );

  test(
    'rideCategories blocks pricing when backend omits a category price',
    () async {
      final repository = _FakeBookingRepository()
        ..calculatedPrices = const {
          'MAGIC': RidePriceEstimate(
            range: 'MAGIC',
            totalPrice: 3100,
            amountReceived: 2800,
          ),
        };
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_destination_4',
              name: 'Marcory',
              address: 'Marcory',
              latitude: 5.3012,
              longitude: -3.9876,
            ),
          );
      container
          .read(bookingOriginSnapshotProvider.notifier)
          .state = BookingOriginSnapshot(
        latitude: 5.348,
        longitude: -4.0135,
        capturedAt: DateTime(2026, 5, 20),
      );

      final result = await _readRideCategories(container);

      expect(result, isEmpty);
      expect(repository.calculateCalls, 1);
      expect(container.read(selectedCategoryProvider), isNull);
      expect(container.read(bookingErrorProvider), pricingUnavailableMessage);
    },
  );

  test(
    'selectedCategory rematches the selected range after a price refresh',
    () async {
      final repository = _FakeBookingRepository();
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      final selectedCategorySub = container.listen(
        selectedCategoryProvider,
        (_, _) {},
        weak: false,
      );
      addTearDown(selectedCategorySub.close);

      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_destination_5',
              name: 'Plateau',
              address: 'Plateau',
              latitude: 5.3245,
              longitude: -4.0201,
            ),
          );
      container
          .read(bookingOriginSnapshotProvider.notifier)
          .state = BookingOriginSnapshot(
        latitude: 5.348,
        longitude: -4.0135,
        capturedAt: DateTime(2026, 5, 20),
      );

      final firstCategories = await _readRideCategories(container);
      final gladiateur = firstCategories.firstWhere(
        (category) => category.id == 'GLADIATEUR',
      );
      container.read(selectedCategoryProvider.notifier).select(gladiateur);

      repository.calculatedPrices = const {
        'MAGIC': RidePriceEstimate(
          range: 'MAGIC',
          totalPrice: 3300,
          amountReceived: 3000,
        ),
        'GLADIATEUR': RidePriceEstimate(
          range: 'GLADIATEUR',
          totalPrice: 4600,
          amountReceived: 4200,
        ),
      };
      container.invalidate(rideCategoriesProvider);
      final refreshedCategories = await container.read(
        rideCategoriesProvider.future,
      );
      expect(
        refreshedCategories
            .firstWhere((category) => category.id == 'GLADIATEUR')
            .price,
        4600,
      );
      await Future<void>.delayed(Duration.zero);

      final selected = container.read(selectedCategoryProvider);
      expect(selected?.id, 'GLADIATEUR');
      expect(selected?.price, 4600);
    },
  );

  test(
    'auto refresh keeps the last priced categories when pricing fails',
    () async {
      final repository = _FakeBookingRepository();
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_destination_6',
              name: 'Marcory',
              address: 'Marcory',
              latitude: 5.3012,
              longitude: -3.9876,
            ),
          );
      container
          .read(bookingOriginSnapshotProvider.notifier)
          .state = BookingOriginSnapshot(
        latitude: 5.348,
        longitude: -4.0135,
        capturedAt: DateTime(2026, 5, 20),
      );

      final firstCategories = await _readRideCategories(container);
      expect(firstCategories, isNotEmpty);
      container.read(bookingErrorProvider.notifier).state = null;

      repository.calculateError = Exception('backend unavailable');
      container.read(ridePriceAutoRefreshInProgressProvider.notifier).state =
          true;
      container.invalidate(rideCategoriesProvider);

      final refreshedCategories = await container.read(
        rideCategoriesProvider.future,
      );

      expect(refreshedCategories.map((category) => category.id), [
        'MAGIC',
        'GLADIATEUR',
      ]);
      expect(container.read(bookingErrorProvider), isNull);
    },
  );
}

class _FakeBookingRepository implements BookingRepository {
  int calculateCalls = 0;
  CalculateRidePricesParams? lastBatchPricingParams;
  CalculateRidePriceParams? lastPricingParams;
  Object? calculateError;
  Map<String, RidePriceEstimate> calculatedPrices = const {
    'MAGIC': RidePriceEstimate(
      range: 'MAGIC',
      totalPrice: 3100,
      amountReceived: 2800,
    ),
    'GLADIATEUR': RidePriceEstimate(
      range: 'GLADIATEUR',
      totalPrice: 4200,
      amountReceived: 3800,
    ),
  };

  @override
  Future<List<RideCategory>> getRideCategories() async {
    return const [
      RideCategory(
        id: 'MAGIC',
        name: 'Magic',
        description: 'Eco',
        price: 2500,
        seats: 4,
        iconAsset: 'assets/images/magic.png',
      ),
      RideCategory(
        id: 'GLADIATEUR',
        name: 'Gladiateur',
        description: 'Confort',
        price: 3000,
        seats: 4,
        iconAsset: 'assets/images/gladiateur.png',
      ),
    ];
  }

  @override
  Future<Map<String, RidePriceEstimate>> calculateRidePrices(
    CalculateRidePricesParams params,
  ) async {
    calculateCalls++;
    lastBatchPricingParams = params;
    final error = calculateError;
    if (error != null) throw error;
    return calculatedPrices;
  }

  @override
  Future<int?> calculateRidePrice(CalculateRidePriceParams params) async {
    calculateCalls++;
    lastPricingParams = params;
    if (params.range == 'MAGIC') return 3100;
    if (params.range == 'GLADIATEUR') return 4200;
    return 5000;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<List<RideCategory>> _readRideCategories(ProviderContainer container) {
  final completer = Completer<List<RideCategory>>();
  late ProviderSubscription<AsyncValue<List<RideCategory>>> subscription;
  subscription = container.listen(rideCategoriesProvider, (previous, next) {
    next.when(
      data: (value) {
        if (!completer.isCompleted) completer.complete(value);
      },
      loading: () {},
      error: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
  }, fireImmediately: true);

  return completer.future.whenComplete(subscription.close);
}
