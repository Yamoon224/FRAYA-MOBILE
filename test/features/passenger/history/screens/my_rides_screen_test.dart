import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/core/utils/logger.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_share_link.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/history/screens/my_rides_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/widgets/fraya_skeleton.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppConfig.instance.init(flavor: AppFlavor.dev);
  AppLogger.instance.init();

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('shows loading state while ride history is pending', (
    tester,
  ) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    final repository = _HandlerBookingRepository(
      onGetUserRides: (_) => completer.future,
    );

    await _pumpScreen(tester, repository: repository, settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FrayaSkeleton), findsWidgets);
  });

  testWidgets('shows empty state when no history is available', (tester) async {
    final repository = _HandlerBookingRepository(
      onGetUserRides: (_) async => const [],
    );

    await _pumpScreen(tester, repository: repository);

    expect(find.text('Aucune course recente'), findsOneWidget);
  });

  testWidgets('shows explicit error state and retries successfully', (
    tester,
  ) async {
    var callCount = 0;
    final repository = _HandlerBookingRepository(
      onGetUserRides: (_) async {
        callCount++;
        if (callCount == 1) {
          throw const NetworkException(message: 'Pas de connexion internet');
        }
        return const [];
      },
    );

    await _pumpScreen(tester, repository: repository);

    expect(find.text('Impossible de charger vos courses.'), findsOneWidget);
    expect(find.text('Pas de connexion internet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Aucune course recente'), findsOneWidget);
    expect(callCount, greaterThanOrEqualTo(2));
  });

  testWidgets('shows filtered history data in the recent tab', (tester) async {
    final repository = _HandlerBookingRepository(
      onGetUserRides: (_) async => [
        _rideMap(
          id: '1',
          status: 'COMPLETED',
          departure: 'Depart Alpha',
          driverRating: 4,
          commentDriver: 'Bon chauffeur',
        ),
        _rideMap(
          id: '2',
          status: 'CANCELLED_PASSENGER',
          departure: 'Depart Beta',
        ),
        _rideMap(id: '3', status: 'SEARCHING', departure: 'Depart Ignore'),
      ],
    );

    await _pumpScreen(tester, repository: repository);

    expect(find.text('Depart Alpha'), findsOneWidget);
    expect(find.text('Depart Beta'), findsOneWidget);
    expect(find.text('Depart Ignore'), findsNothing);
    expect(find.text('4.0'), findsAtLeastNWidgets(1));
    expect(find.text('"Bon chauffeur"'), findsOneWidget);
    expect(find.text('Voir toutes les courses'), findsOneWidget);
  });

  testWidgets('pull refresh reloads history and resets to recent tab', (
    tester,
  ) async {
    var callCount = 0;
    final repository = _HandlerBookingRepository(
      onGetUserRides: (_) async {
        callCount++;
        return const [];
      },
    );

    await _pumpScreen(tester, repository: repository);

    expect(callCount, 1);

    await tester.tap(find.text('Toutes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aucune course sur cette'), findsOneWidget);

    await tester.drag(
      find.textContaining('Aucune course sur cette'),
      const Offset(0, 360),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(callCount, 2);
    expect(find.text('Aucune course recente'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required BookingRepository repository,
  bool settle = true,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'access_token': 'passenger-token',
    'auth_user_data': '{"id":7}',
  });
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        passengerAuthProvider.overrideWith(
          (ref) => _TestPassengerAuthNotifier(_authenticatedState()),
        ),
        passengerBookingRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: MyRidesScreen()),
    ),
  );
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  }
}

AuthState _authenticatedState() {
  return AuthState(status: AuthStatus.authenticated, userData: {'id': 7});
}

Map<String, dynamic> _rideMap({
  required String id,
  required String status,
  required String departure,
  int? driverRating,
  String? commentDriver,
}) {
  return {
    'id': id,
    'status': status,
    'departureAddress': departure,
    'arrivalAddress': 'Plateau',
    'createdAt': '2026-05-20T10:00:00.000Z',
    'requestedRange': 'MAGIC',
    'finalPrice': 2500,
    'driverRating': driverRating,
    'commentDriver': commentDriver,
  };
}

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
  set state(AuthState value) {
    if (_sameState(super.state, value)) return;
    super.state = value;
  }

  bool _sameState(AuthState left, AuthState right) {
    return left.status == right.status &&
        left.errorMessage == right.errorMessage &&
        _sameUserData(left.userData, right.userData);
  }

  bool _sameUserData(Map<String, dynamic>? left, Map<String, dynamic>? right) {
    if (identical(left, right)) return true;
    if (left == null || right == null) return left == right;
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) return false;
    }
    return true;
  }
}

class _HandlerBookingRepository implements BookingRepository {
  _HandlerBookingRepository({required this.onGetUserRides});

  final Future<List<Map<String, dynamic>>> Function(int userId) onGetUserRides;

  @override
  Future<List<Map<String, dynamic>>> getUserRides(int userId) {
    return onGetUserRides(userId);
  }

  @override
  Future<List<RideCategory>> getRideCategories() async => const [];

  @override
  Future<Map<String, RidePriceEstimate>> calculateRidePrices(
    CalculateRidePricesParams params,
  ) async => const {};

  @override
  Future<int?> calculateRidePrice(CalculateRidePriceParams params) async =>
      null;

  @override
  Future<String> requestRide(RequestRideParams params) async => '';

  @override
  Future<bool> cancelRide(String rideId, {String? reason}) async => false;

  @override
  Future<ActiveRide?> getActiveRide(int userId, {String? rideId}) async => null;

  @override
  Future<RideShareLink> createRideShareLink({
    required String rideId,
    int expiresIn = 60,
  }) async {
    return RideShareLink(
      token: 'token-$rideId',
      url: 'https://example.test/share/$rideId',
      expiresAt: DateTime(2026, 1, 1),
      isValid: true,
    );
  }

  @override
  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  }) async => RateRideOutcome.submitted;

  @override
  Future<bool> triggerSos({
    required String rideId,
    required int userId,
    required double lat,
    required double lng,
    String? notes,
  }) async => false;

  @override
  Future<bool> createSupportTicket({
    required String rideId,
    required int userId,
    required String category,
    String? description,
  }) async => false;
}
