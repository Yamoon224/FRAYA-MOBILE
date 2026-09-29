import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/route_directions_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/selected_route_index_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'passenger-token',
      'auth_user_data': '{"id":7}',
    });
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  test('startSearching always submits the main route metrics', () async {
    final repository = _CapturingBookingRepository();
    final container = ProviderContainer(
      overrides: [
        passengerAuthProvider.overrideWith(
          (ref) => _TestPassengerAuthNotifier(
            AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
          ),
        ),
        activeRideCheckProvider.overrideWith((ref) async => null),
        passengerBookingRepositoryProvider.overrideWithValue(repository),
        routeDirectionsProvider.overrideWith((ref) async => _directions),
        currentLocationProvider.overrideWith((ref) => Stream.value(null)),
        formattedAddressProvider.overrideWith((ref) => 'Position actuelle'),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(selectedPickupProvider.notifier)
        .setPlace(
          const PlaceDetails(
            placeId: 'pickup',
            name: 'Pickup',
            address: 'Cocody',
            latitude: 5.31,
            longitude: -4.01,
          ),
        );
    container
        .read(selectedDestinationProvider.notifier)
        .setPlace(
          const PlaceDetails(
            placeId: 'destination',
            name: 'Destination',
            address: 'Plateau',
            latitude: 5.25,
            longitude: -3.93,
          ),
        );
    container.read(selectedCategoryProvider.notifier).select(_category);
    container.read(selectedRouteIndexProvider.notifier).state = 1;
    await container.read(routeDirectionsProvider.future);

    await container.read(bookingFlowProvider.notifier).startSearching();

    final params = repository.lastRequest;
    expect(params, isNotNull);
    expect(params!.estimatedDistance, 1.2);
    expect(params.estimatedDuration, 5);
    expect(params.durationInTraffic, '6');
    expect(params.trafficPercentage, '20');
  });
}

final _directions = DirectionsResult(
  routes: const [
    DirectionsRoute(
      encodedPolyline: '',
      distanceText: '1.2 km',
      distanceValue: 1200,
      durationText: '5 min',
      durationValue: 300,
      arrivalTime: null,
      durationInTrafficValue: 360,
      trafficSegments: [],
      hasTrafficData: false,
    ),
    DirectionsRoute(
      encodedPolyline: '',
      distanceText: '0.9 km',
      distanceValue: 900,
      durationText: '4 min',
      durationValue: 240,
      arrivalTime: null,
      durationInTrafficValue: 240,
      trafficSegments: [],
      hasTrafficData: false,
    ),
  ],
);

const _category = RideCategory(
  id: 'MAGIC',
  name: 'Magic',
  description: 'Economique',
  price: 2200,
  seats: 4,
  iconAsset: 'assets/images/magic.png',
);

class _CapturingBookingRepository implements BookingRepository {
  RequestRideParams? lastRequest;

  @override
  Future<List<RideCategory>> getRideCategories() async => const [_category];

  @override
  Future<Map<String, RidePriceEstimate>> calculateRidePrices(
    CalculateRidePricesParams params,
  ) async {
    return const {
      'MAGIC': RidePriceEstimate(
        range: 'MAGIC',
        totalPrice: 2200,
        amountReceived: 2000,
      ),
    };
  }

  @override
  Future<String> requestRide(RequestRideParams params) async {
    lastRequest = params;
    return _activeRide.rideId;
  }

  @override
  Future<ActiveRide?> getActiveRide(int userId, {String? rideId}) async {
    return _activeRide;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _activeRide = ActiveRide(
  rideId: 'ride_1',
  driverName: 'Chauffeur',
  driverPhoto: 'assets/images/driver_placeholder.png',
  driverRating: 4.8,
  carModel: 'Toyota Corolla',
  carPlate: 'AA-123-BB',
  pickupAddress: 'Cocody',
  destinationAddress: 'Plateau',
  driverLocation: LatLng(5.35, -4.01),
  pickupLocation: LatLng(5.31, -4.01),
  destinationLocation: LatLng(5.25, -3.93),
  status: RideStatus.pending,
  estimatedPrice: 2200,
);

class _TestPassengerAuthNotifier extends PassengerAuthNotifier {
  _TestPassengerAuthNotifier(AuthState initialState)
    : super(
        loginUsecase: LoginPassengerUsecase(PassengerAuthRepository()),
        registerStep1Usecase: RegisterStep1Usecase(PassengerAuthRepository()),
        registerStep2Usecase: RegisterStep2Usecase(PassengerAuthRepository()),
        registerStep3Usecase: RegisterStep3Usecase(PassengerAuthRepository()),
        logoutUsecase: LogoutPassengerUsecase(),
      ) {
    state = initialState;
  }

  @override
  Future<void> logout() async {
    if (!mounted) return;
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}
