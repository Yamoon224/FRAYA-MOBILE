import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/core/utils/logger.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/calculate_ride_category_prices.dart';
import 'package:fraya_mobile/domain/usecases/passenger/get_ride_categories.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/history/details/providers/ride_details_controller.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

void main() {
  AppConfig.instance.init(flavor: AppFlavor.dev);
  AppLogger.instance.init();

  testWidgets(
    'reorderRide fallback keeps navigation and base categories when placeId is missing',
    (tester) async {
      final repository = _FakeBookingRepository();
      final container = ProviderContainer(
        overrides: [
          placesServiceProvider.overrideWith((ref) => _FallbackPlacesService()),
          getRideCategoriesUseCaseProvider.overrideWithValue(
            GetRideCategoriesUseCase(repository),
          ),
          calculateRideCategoryPricesUseCaseProvider.overrideWithValue(
            CalculateRideCategoryPricesUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      var navigateCalls = 0;
      final context = tester.element(find.byType(SizedBox));
      await container.read(rideCategoriesProvider.future);
      expect(container.read(selectedCategoryProvider), isNotNull);

      await container
          .read(rideDetailsControllerProvider.notifier)
          .reorderRide(
            context,
            _buildRide(),
            onNavigate: () => navigateCalls++,
          );
      await tester.pump(const Duration(milliseconds: 350));

      final destination = container.read(selectedDestinationProvider);
      final categories = await container.read(rideCategoriesProvider.future);

      expect(navigateCalls, 1);
      expect(destination, isNotNull);
      expect(destination!.placeId, '');
      expect(container.read(bookingErrorProvider), isNotNull);
      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.routePreview,
      );
      expect(container.read(selectedCategoryProvider), isNull);
      expect(categories, isNotEmpty);
      expect(categories.first.price, 2500);
      expect(repository.calculateCalls, 0);
    },
  );
}

Ride _buildRide() {
  return Ride(
    id: 'ride_1',
    departureAddress: 'Cocody, Abidjan',
    arrivalAddress: 'Destination manuelle',
    departureLat: 5.35,
    departureLng: -3.99,
    arrivalLat: 5.26,
    arrivalLng: -3.94,
    price: 3000,
    date: DateTime(2026, 5, 20),
    status: RideStatus.completed,
    vehicleRange: 'MAGIC',
  );
}

class _FallbackPlacesService extends PlacesService {
  @override
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String query, {
    String? sessionToken,
    String language = 'fr',
    String components = 'country:ci',
    double? originLat,
    double? originLng,
    bool bypassCache = false,
  }) async {
    return const [];
  }
}

class _FakeBookingRepository implements BookingRepository {
  int calculateCalls = 0;

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
    ];
  }

  @override
  Future<Map<String, RidePriceEstimate>> calculateRidePrices(
    CalculateRidePricesParams params,
  ) async {
    calculateCalls++;
    return const {
      'MAGIC': RidePriceEstimate(
        range: 'MAGIC',
        totalPrice: 3100,
        amountReceived: 2800,
      ),
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
