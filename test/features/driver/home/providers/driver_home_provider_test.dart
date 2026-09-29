import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/core/realtime/realtime_events.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_overview.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_package.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_package_subscription_result.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_reload_result.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/driver_ride_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_status_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_wallet_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/accept_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/cancel_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/complete_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/get_driver_active_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/mark_driver_ride_arrived.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/start_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/status/update_driver_status.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_state.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_notifier.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_ride_dependencies.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_status_dependencies.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/driver_wallet_dependencies.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/driver_wallet_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/driver_test_doubles.dart';

class RecordingDriverRideRepository implements DriverRideRepository {
  List<DriverRide> historyRides = const [];
  List<DriverRide> availableRides = const [];
  DriverRide? activeRide;

  Object? availableRidesError;
  Object? activeRideError;
  Object? acceptRideError;

  int getAvailableRidesCalls = 0;
  int getActiveRideCalls = 0;
  int acceptRideCalls = 0;
  int completeRideCalls = 0;
  int cancelRideCalls = 0;

  String? lastAcceptedRideId;
  int? lastAcceptedDriverId;
  int? lastAcceptedVehicleId;
  String? lastArrivedRideId;
  double? lastArrivedLat;
  double? lastArrivedLng;
  int sendLocationCalls = 0;
  int sendAvailabilityLocationCalls = 0;
  String? lastSentRideId;
  int? lastSentDriverId;
  double? lastSentLat;
  double? lastSentLng;
  double? lastSentAvailabilityLat;
  double? lastSentAvailabilityLng;
  Completer<void>? acceptRideCompleter;

  @override
  Future<List<DriverRide>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    getAvailableRidesCalls++;
    if (availableRidesError != null) {
      throw availableRidesError!;
    }
    return availableRides;
  }

  @override
  Future<DriverRide?> getActiveRide(int driverId, {String? rideId}) async {
    getActiveRideCalls++;
    if (activeRideError != null) {
      throw activeRideError!;
    }
    return activeRide;
  }

  @override
  Future<List<DriverRide>> getHistoryRides() async => historyRides;

  @override
  Future<void> acceptRide(
    String rideId, {
    required int driverId,
    required int vehicleId,
  }) async {
    acceptRideCalls++;
    lastAcceptedRideId = rideId;
    lastAcceptedDriverId = driverId;
    lastAcceptedVehicleId = vehicleId;
    if (acceptRideError != null) {
      throw acceptRideError!;
    }
    if (acceptRideCompleter != null) {
      await acceptRideCompleter!.future;
    }
  }

  @override
  Future<void> cancelRide(String rideId, {String? reason}) async {
    cancelRideCalls++;
    activeRide = null;
  }

  @override
  Future<void> completeRide(
    String rideId, {
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    required int additionnalFreeSeconds,
  }) async {
    completeRideCalls++;
    activeRide = null;
  }

  @override
  Future<void> markArrived(
    String rideId, {
    required double driverLat,
    required double driverLng,
  }) async {
    lastArrivedRideId = rideId;
    lastArrivedLat = driverLat;
    lastArrivedLng = driverLng;
  }

  @override
  Future<void> startRide(String rideId) async {}

  @override
  Future<void> sendLocation({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  }) async {
    sendLocationCalls++;
    lastSentRideId = rideId;
    lastSentDriverId = driverId;
    lastSentLat = lat;
    lastSentLng = lng;
  }

  @override
  Future<void> sendAvailabilityLocation({
    required double lat,
    required double lng,
  }) async {
    sendAvailabilityLocationCalls++;
    lastSentAvailabilityLat = lat;
    lastSentAvailabilityLng = lng;
  }
}

class RecordingDriverStatusRepository implements DriverStatusRepository {
  int updateStatusCalls = 0;
  bool? lastIsOnline;
  final List<bool> isOnlineValues = [];
  int sendHeartbeatCalls = 0;
  Object? error;

  @override
  Future<void> updateStatus({required bool isOnline}) async {
    updateStatusCalls++;
    lastIsOnline = isOnline;
    isOnlineValues.add(isOnline);
    if (error != null) {
      throw error!;
    }
  }

  @override
  Future<void> sendHeartbeat() async {
    sendHeartbeatCalls++;
    if (error != null) throw error!;
  }
}

class RecordingDriverWalletRepository implements DriverWalletRepository {
  int fetchWalletOverviewCalls = 0;

  @override
  Future<DriverWalletOverview> fetchWalletOverview() async {
    fetchWalletOverviewCalls++;
    return const DriverWalletOverview(
      balance: 12000,
      walletId: 'Fra-I4JUY',
      transactions: [],
    );
  }

  @override
  Future<List<DriverWalletPackage>> fetchPackages() async {
    return const [];
  }

  @override
  Future<DriverWalletReloadResult> reloadWallet({
    required double amount,
    String? walletId,
  }) async {
    return const DriverWalletReloadResult(message: 'OK');
  }

  @override
  Future<DriverWalletPackageSubscriptionResult> subscribeToPackage({
    required int sidUserId,
    required int packageId,
  }) async {
    return const DriverWalletPackageSubscriptionResult(message: 'OK');
  }

  @override
  Future<void> withdrawWallet({
    required double amount,
    String? walletId,
  }) async {}
}

void main() {
  group('driverHomeProvider location sync', () {
    test('sends active ride location with rideId and driverId', () async {
      await _initLocalStorageForProviderTest();
      final locationController = StreamController<Position?>();
      final repository = RecordingDriverRideRepository()
        ..activeRide = _ride(id: 'ride-707', status: RideStatus.accepted);
      final statusRepository = RecordingDriverStatusRepository();
      final authNotifier = FakeDriverAuthNotifier(_approvedAuthState);
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith(
            (ref) => locationController.stream,
          ),
          driverRideRepositoryProvider.overrideWith((ref) => repository),
          driverStatusRepositoryProvider.overrideWith(
            (ref) => statusRepository,
          ),
          driverAuthProvider.overrideWith((ref) => authNotifier),
        ],
      );
      final subscription = container.listen<DriverHomeState>(
        driverHomeProvider,
        (_, _) {},
      );
      addTearDown(() async {
        subscription.close();
        container.dispose();
        await locationController.close();
        await LocalStorage.instance.setBool('driver_is_online_24', false);
      });

      final notifier = container.read(driverHomeProvider.notifier);
      await notifier.setOnline(true);
      await Future<void>.delayed(Duration.zero);
      locationController.add(_position(latitude: 5.36, longitude: -4.02));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repository.sendLocationCalls, 1);
      expect(repository.lastSentRideId, 'ride-707');
      expect(repository.lastSentDriverId, 14);
      expect(repository.lastSentLat, 5.36);
      expect(repository.lastSentLng, -4.02);
    });

    test(
      'sends availability location while online without active ride',
      () async {
        await _initLocalStorageForProviderTest();
        final locationController = StreamController<Position?>();
        final repository = RecordingDriverRideRepository();
        final statusRepository = RecordingDriverStatusRepository();
        final authNotifier = FakeDriverAuthNotifier(_approvedAuthState);
        final container = ProviderContainer(
          overrides: [
            currentLocationProvider.overrideWith(
              (ref) => locationController.stream,
            ),
            driverRideRepositoryProvider.overrideWith((ref) => repository),
            driverStatusRepositoryProvider.overrideWith(
              (ref) => statusRepository,
            ),
            driverAuthProvider.overrideWith((ref) => authNotifier),
          ],
        );
        final subscription = container.listen<DriverHomeState>(
          driverHomeProvider,
          (_, _) {},
        );
        addTearDown(() async {
          subscription.close();
          container.dispose();
          await locationController.close();
          await LocalStorage.instance.setBool('driver_is_online_24', false);
        });

        final notifier = container.read(driverHomeProvider.notifier);
        await notifier.setOnline(true);
        await Future<void>.delayed(Duration.zero);
        locationController.add(_position(latitude: 5.36, longitude: -4.02));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(repository.sendLocationCalls, 0);
        expect(repository.sendAvailabilityLocationCalls, 1);
        expect(repository.lastSentAvailabilityLat, 5.36);
        expect(repository.lastSentAvailabilityLng, -4.02);
      },
    );

    test('does not send availability location while offline', () async {
      await _initLocalStorageForProviderTest();
      final locationController = StreamController<Position?>();
      final repository = RecordingDriverRideRepository();
      final statusRepository = RecordingDriverStatusRepository();
      final authNotifier = FakeDriverAuthNotifier(_approvedAuthState);
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith(
            (ref) => locationController.stream,
          ),
          driverRideRepositoryProvider.overrideWith((ref) => repository),
          driverStatusRepositoryProvider.overrideWith(
            (ref) => statusRepository,
          ),
          driverAuthProvider.overrideWith((ref) => authNotifier),
        ],
      );
      final subscription = container.listen<DriverHomeState>(
        driverHomeProvider,
        (_, _) {},
      );
      addTearDown(() async {
        subscription.close();
        container.dispose();
        await locationController.close();
      });

      locationController.add(_position(latitude: 5.36, longitude: -4.02));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repository.sendLocationCalls, 0);
      expect(repository.sendAvailabilityLocationCalls, 0);
    });

    test('does not send active ride location without driverId', () async {
      await _initLocalStorageForProviderTest();
      final locationController = StreamController<Position?>();
      final repository = RecordingDriverRideRepository()
        ..activeRide = _ride(
          id: 'ride-no-driver-id',
          status: RideStatus.accepted,
        );
      final statusRepository = RecordingDriverStatusRepository();
      final authNotifier = FakeDriverAuthNotifier(_approvedAuthState);
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith(
            (ref) => locationController.stream,
          ),
          driverRideRepositoryProvider.overrideWith((ref) => repository),
          driverStatusRepositoryProvider.overrideWith(
            (ref) => statusRepository,
          ),
          driverAuthProvider.overrideWith((ref) => authNotifier),
        ],
      );
      final subscription = container.listen<DriverHomeState>(
        driverHomeProvider,
        (_, _) {},
      );
      addTearDown(() async {
        subscription.close();
        container.dispose();
        await locationController.close();
        await LocalStorage.instance.setBool('driver_is_online_24', false);
      });

      final notifier = container.read(driverHomeProvider.notifier);
      await notifier.setOnline(true);
      expect(notifier.state.activeRide?.rideId, 'ride-no-driver-id');
      authNotifier.setTestState(
        AuthState(
          status: AuthStatus.authenticated,
          userData: const {
            'userId': 24,
            'kycStatus': 'APPROVED',
            'vehicleStatus': 'APPROVED',
            'vehicleId': 7,
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      locationController.add(_position(latitude: 5.37, longitude: -4.03));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repository.sendLocationCalls, 0);
    });

    test('refreshes wallet overview after completing a ride', () async {
      await _initLocalStorageForProviderTest();
      final locationController = StreamController<Position?>();
      final repository = RecordingDriverRideRepository()
        ..activeRide = _ride(id: 'ride-wallet', status: RideStatus.inProgress);
      final statusRepository = RecordingDriverStatusRepository();
      final walletRepository = RecordingDriverWalletRepository();
      final authNotifier = FakeDriverAuthNotifier(_approvedAuthState);
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith(
            (ref) => locationController.stream,
          ),
          driverRideRepositoryProvider.overrideWith((ref) => repository),
          driverStatusRepositoryProvider.overrideWith(
            (ref) => statusRepository,
          ),
          driverAuthProvider.overrideWith((ref) => authNotifier),
          driverWalletRepositoryProvider.overrideWithValue(walletRepository),
        ],
      );
      final homeSubscription = container.listen<DriverHomeState>(
        driverHomeProvider,
        (_, _) {},
      );
      final walletSubscription = container.listen(
        driverWalletProvider,
        (_, _) {},
      );
      addTearDown(() async {
        homeSubscription.close();
        walletSubscription.close();
        container.dispose();
        await locationController.close();
        await LocalStorage.instance.setBool('driver_is_online_24', false);
      });

      await _waitUntilWalletLoaded(container);
      final initialWalletCalls = walletRepository.fetchWalletOverviewCalls;
      final notifier = container.read(driverHomeProvider.notifier);
      await notifier.setOnline(true);

      final success = await notifier.completeRide(
        rideId: 'ride-wallet',
        finalDistanceKm: 8.5,
        finalDurationMin: 18,
        finalPrice: 3500,
      );

      expect(success, isTrue);
      await _waitUntilWalletFetchCalls(
        walletRepository,
        initialWalletCalls + 1,
      );
      expect(walletRepository.fetchWalletOverviewCalls, initialWalletCalls + 1);
    });
  });

  group('DriverHomeNotifier', () {
    late RecordingDriverRideRepository repository;
    late RecordingDriverStatusRepository statusRepository;
    late DriverHomeNotifier notifier;

    setUp(() async {
      await _initLocalStorageForProviderTest();
      await LocalStorage.instance.setBool('driver_is_online_24', false);
      repository = RecordingDriverRideRepository();
      statusRepository = RecordingDriverStatusRepository();
      notifier = DriverHomeNotifier(
        acceptRideUseCase: AcceptDriverRideUseCase(repository),
        markArrivedUseCase: MarkDriverRideArrivedUseCase(repository),
        startRideUseCase: StartDriverRideUseCase(repository),
        completeRideUseCase: CompleteDriverRideUseCase(repository),
        cancelRideUseCase: CancelDriverRideUseCase(repository),
        fetchAvailableRidesUseCase: FetchAvailableDriverRidesUseCase(
          repository,
        ),
        getActiveRideUseCase: GetDriverActiveRideUseCase(repository),
        updateDriverStatusUseCase: UpdateDriverStatusUseCase(statusRepository),
        pollingInterval: const Duration(milliseconds: 20),
      );
    });

    tearDown(() {
      notifier.dispose();
    });

    test('blocks online mode when admin validation is missing', () async {
      notifier.syncUserData(const {
        'driverId': 14,
        'kycStatus': 'PENDING_VALIDATION',
        'vehicleStatus': 'APPROVED',
        'vehicleId': 7,
      });

      await notifier.setOnline(true);

      expect(notifier.state.status, DriverHomeStatus.blocked);
      expect(notifier.state.isOnline, isFalse);
      expect(
        notifier.state.errorMessage,
        'Votre dossier KYC est en attente de validation par un administrateur.',
      );
      expect(statusRepository.updateStatusCalls, 0);
      expect(repository.getAvailableRidesCalls, 0);
      expect(repository.getActiveRideCalls, 0);
    });

    test('loads available rides and polling refreshes while online', () async {
      repository.availableRides = [_ride(id: '101')];
      notifier.syncUserData(const {
        'userId': 24,
        'driverId': 14,
        'kycStatus': 'APPROVED',
        'vehicleStatus': 'APPROVED',
        'vehicleId': 7,
      });

      await notifier.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(notifier.state.isOnline, isTrue);
      expect(notifier.state.status, DriverHomeStatus.ready);
      expect(notifier.state.availableRides, hasLength(1));
      expect(statusRepository.updateStatusCalls, 1);
      expect(statusRepository.lastIsOnline, isTrue);
      expect(repository.getAvailableRidesCalls, greaterThanOrEqualTo(2));
    });

    test('calls backend endpoint when going offline', () async {
      repository.availableRides = [_ride(id: '111')];
      notifier.syncUserData(_approvedUserData);

      await notifier.setOnline(true);
      await notifier.setOnline(false);

      expect(statusRepository.updateStatusCalls, 2);
      expect(statusRepository.isOnlineValues, [true, false]);
      expect(notifier.state.isOnline, isFalse);
      expect(notifier.state.status, DriverHomeStatus.idle);
    });

    test('blocks going offline while a ride is active', () async {
      repository.activeRide = _ride(
        id: 'active-111',
        status: RideStatus.accepted,
      );
      notifier.syncUserData(_approvedUserData);

      await notifier.setOnline(true);
      await notifier.setOnline(false);

      expect(statusRepository.isOnlineValues, [true]);
      expect(notifier.state.isOnline, isTrue);
      expect(notifier.state.activeRide?.rideId, 'active-111');
      expect(
        notifier.state.errorMessage,
        'Vous ne pouvez pas passer hors ligne pendant une course en cours.',
      );
      expect(LocalStorage.instance.getBool('driver_is_online_24'), isTrue);
    });

    test('app closing keeps online intent and sets backend offline', () async {
      notifier.syncUserData(_approvedUserData);

      await notifier.setOnline(true);
      await notifier.handleAppClosing();

      expect(statusRepository.isOnlineValues, [true, false]);
      expect(notifier.state.isOnline, isFalse);
      expect(LocalStorage.instance.getBool('driver_is_online_24'), isTrue);
    });

    test('restores online status from the saved closing intent', () async {
      notifier.syncUserData(_approvedUserData);

      await notifier.setOnline(true);
      await notifier.handleAppClosing();
      await notifier.restoreOnlineStatus();

      expect(statusRepository.isOnlineValues, [true, false, true]);
      expect(notifier.state.isOnline, isTrue);
    });

    test(
      'app closing does not set backend offline during an active ride',
      () async {
        repository.activeRide = _ride(
          id: 'active-close',
          status: RideStatus.inProgress,
        );
        notifier.syncUserData(_approvedUserData);

        await notifier.setOnline(true);
        await notifier.handleAppClosing();

        expect(statusRepository.isOnlineValues, [true]);
        expect(notifier.state.isOnline, isTrue);
        expect(LocalStorage.instance.getBool('driver_is_online_24'), isTrue);
      },
    );

    test('app closing while offline removes the saved online intent', () async {
      notifier.syncUserData(_approvedUserData);
      await Future<void>.delayed(Duration.zero);
      await LocalStorage.instance.setBool('driver_is_online_24', true);

      await notifier.handleAppClosing();

      expect(statusRepository.updateStatusCalls, 0);
      expect(LocalStorage.instance.getBool('driver_is_online_24'), isNull);
    });

    test(
      'refreshes active ride instead of available rides when one exists',
      () async {
        repository.activeRide = _ride(id: '202', status: RideStatus.accepted);
        notifier.syncUserData(const {
          'userId': 24,
          'driverId': 14,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
          'vehicleId': 7,
        });

        await notifier.setOnline(true);
        final activeRideCallsAfterOnline = repository.getActiveRideCalls;
        await notifier.refreshHome();

        expect(notifier.state.activeRide?.rideId, '202');
        expect(
          repository.getActiveRideCalls,
          greaterThan(activeRideCallsAfterOnline),
        );
        expect(repository.getAvailableRidesCalls, 0);
      },
    );

    test('keeps polling active ride only when a ride is in progress', () async {
      repository.activeRide = _ride(id: '212', status: RideStatus.accepted);
      notifier.syncUserData(_approvedUserData);

      await notifier.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      notifier.stopPolling();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repository.getActiveRideCalls, greaterThanOrEqualTo(2));
      expect(repository.getAvailableRidesCalls, 0);
    });

    test(
      'applyRealtimeRideStatus clears the active ride and refreshes available rides',
      () async {
        repository.activeRide = _ride(id: '213', status: RideStatus.accepted);
        repository.availableRides = [_ride(id: '214')];
        notifier.syncUserData(_approvedUserData);

        await notifier.setOnline(true);
        final availableBefore = repository.getAvailableRidesCalls;
        repository.activeRide = null;

        await notifier.applyRealtimeRideStatus(
          DriverRideStatusRealtimeEvent(
            rideId: '213',
            status: 'CANCELLED',
            updatedAt: DateTime.parse('2026-05-22T12:10:00.000Z'),
            reason: 'Client a annule',
          ),
        );

        expect(notifier.state.activeRide, isNull);
        expect(notifier.state.availableRides, hasLength(1));
        expect(repository.getAvailableRidesCalls, greaterThan(availableBefore));
      },
    );

    test(
      'completeRide resumes available ride search when active ride ends',
      () async {
        repository.activeRide = _ride(id: '313', status: RideStatus.inProgress);
        repository.availableRides = [_ride(id: '314')];
        notifier.syncUserData(_approvedUserData);

        await notifier.setOnline(true);
        final availableBefore = repository.getAvailableRidesCalls;
        final success = await notifier.completeRide(
          rideId: '313',
          finalDistanceKm: 8.5,
          finalDurationMin: 18,
          finalPrice: 3500,
        );

        expect(success, isTrue);
        expect(repository.completeRideCalls, 1);
        expect(repository.getAvailableRidesCalls, greaterThan(availableBefore));
        expect(notifier.state.activeRide, isNull);
        expect(notifier.state.availableRides, isNotEmpty);
      },
    );

    test(
      'cancelRide resumes available ride search when active ride ends',
      () async {
        repository.activeRide = _ride(id: '315', status: RideStatus.accepted);
        repository.availableRides = [_ride(id: '316')];
        notifier.syncUserData(_approvedUserData);

        await notifier.setOnline(true);
        final availableBefore = repository.getAvailableRidesCalls;
        final success = await notifier.cancelRide(
          rideId: '315',
          reason: 'Client indisponible',
        );

        expect(success, isTrue);
        expect(repository.cancelRideCalls, 1);
        expect(repository.getAvailableRidesCalls, greaterThan(availableBefore));
        expect(notifier.state.activeRide, isNull);
        expect(notifier.state.availableRides, isNotEmpty);
      },
    );

    test('accepts a ride and resynchronizes active ride state', () async {
      repository.availableRides = [_ride(id: '303')];
      notifier.syncUserData(const {
        'userId': 24,
        'driverId': 14,
        'kycStatus': 'APPROVED',
        'vehicleStatus': 'APPROVED',
        'vehicleId': 7,
      });
      await notifier.setOnline(true);

      repository.activeRide = _ride(id: '303', status: RideStatus.accepted);
      final success = await notifier.acceptRide('303');

      expect(success, isTrue);
      expect(repository.acceptRideCalls, 1);
      expect(repository.lastAcceptedRideId, '303');
      expect(repository.lastAcceptedDriverId, 14);
      expect(repository.lastAcceptedVehicleId, 7);
      expect(notifier.state.activeRide?.rideId, '303');
      expect(notifier.state.activeRide?.status, RideStatus.accepted);
      expect(notifier.state.isSubmittingAction, isFalse);
    });

    test(
      'prevents double submission while a critical action is running',
      () async {
        repository.availableRides = [_ride(id: '404')];
        repository.acceptRideCompleter = Completer<void>();
        notifier.syncUserData(const {
          'userId': 24,
          'driverId': 14,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
          'vehicleId': 7,
        });
        await notifier.setOnline(true);

        final firstCall = notifier.acceptRide('404');
        final secondCall = await notifier.acceptRide('404');
        repository.activeRide = _ride(id: '404', status: RideStatus.accepted);
        repository.acceptRideCompleter!.complete();
        final firstResult = await firstCall;

        expect(secondCall, isFalse);
        expect(firstResult, isTrue);
        expect(repository.acceptRideCalls, 1);
      },
    );

    test(
      'declineRideLocally removes an available ride while offline of course',
      () async {
        repository.availableRides = [
          _ride(id: 'decline-1'),
          _ride(id: 'decline-2'),
        ];
        notifier.syncUserData(_approvedUserData);

        await notifier.setOnline(true);
        await notifier.declineRideLocally('decline-1');

        expect(
          notifier.state.availableRides.map((ride) => ride.rideId).toList(),
          ['decline-2'],
        );
        expect(notifier.state.ignoredIncomingRideIds, ['decline-1']);
      },
    );

    test(
      'declineRideLocally keeps a pre-arrival ride hidden after refresh',
      () async {
        repository.activeRide = _ride(
          id: 'active-pre-arrival',
          status: RideStatus.accepted,
        );
        repository.availableRides = [_ride(id: 'decline-pre-arrival')];
        notifier.syncUserData(_approvedUserData);

        await notifier.setOnline(true);
        notifier.syncRealtimeLocation(const LatLng(5.3201, -4.0101));
        await notifier.refreshHome();
        await notifier.declineRideLocally('decline-pre-arrival');
        await notifier.refreshHome();

        expect(notifier.state.activeRide?.rideId, 'active-pre-arrival');
        expect(notifier.state.availableRides, isEmpty);
        expect(notifier.state.ignoredIncomingRideIds, ['decline-pre-arrival']);
      },
    );

    test(
      'restores ignored incoming ride ids across notifier recreation',
      () async {
        repository.availableRides = [
          _ride(id: 'persisted-ride'),
          _ride(id: 'visible-ride'),
        ];
        notifier.syncUserData(_approvedUserData);
        await notifier.setOnline(true);
        await notifier.declineRideLocally('persisted-ride');
        notifier.dispose();

        final recreatedRepository = RecordingDriverRideRepository()
          ..availableRides = [
            _ride(id: 'persisted-ride'),
            _ride(id: 'visible-ride'),
          ];
        // Reassign so the outer tearDown disposes the recreated instance.
        notifier = DriverHomeNotifier(
          acceptRideUseCase: AcceptDriverRideUseCase(recreatedRepository),
          markArrivedUseCase: MarkDriverRideArrivedUseCase(recreatedRepository),
          startRideUseCase: StartDriverRideUseCase(recreatedRepository),
          completeRideUseCase: CompleteDriverRideUseCase(recreatedRepository),
          cancelRideUseCase: CancelDriverRideUseCase(recreatedRepository),
          fetchAvailableRidesUseCase: FetchAvailableDriverRidesUseCase(
            recreatedRepository,
          ),
          getActiveRideUseCase: GetDriverActiveRideUseCase(recreatedRepository),
          updateDriverStatusUseCase: UpdateDriverStatusUseCase(
            statusRepository,
          ),
          pollingInterval: const Duration(milliseconds: 20),
        );

        notifier.syncUserData(_approvedUserData);
        await Future<void>.delayed(Duration.zero);
        await notifier.setOnline(true);

        expect(notifier.state.ignoredIncomingRideIds, ['persisted-ride']);
        expect(
          notifier.state.availableRides.map((ride) => ride.rideId).toList(),
          ['visible-ride'],
        );
      },
    );

    test('keeps only the 500 most recent ignored incoming ride ids', () async {
      notifier.syncUserData(_approvedUserData);

      for (var index = 0; index < 510; index++) {
        await notifier.declineRideLocally('ride-$index');
      }

      expect(notifier.state.ignoredIncomingRideIds, hasLength(500));
      expect(notifier.state.ignoredIncomingRideIds.first, 'ride-10');
      expect(notifier.state.ignoredIncomingRideIds.last, 'ride-509');
    });

    test('syncs realtime location into state and active ride', () async {
      repository.activeRide = _ride(id: '505', status: RideStatus.accepted);
      notifier.syncUserData(_approvedUserData);

      await notifier.setOnline(true);
      notifier.syncRealtimeLocation(const LatLng(5.36, -4.02));

      expect(notifier.state.currentDriverLocation, const LatLng(5.36, -4.02));
      expect(
        notifier.state.activeRide?.driverLocation,
        const LatLng(5.36, -4.02),
      );
    });

    test('keeps realtime location after refresh', () async {
      repository.activeRide = _ride(id: '606', status: RideStatus.accepted);
      notifier.syncUserData(_approvedUserData);
      notifier.syncRealtimeLocation(const LatLng(5.37, -4.03));

      await notifier.setOnline(true);
      await notifier.refreshHome();

      expect(
        notifier.state.activeRide?.driverLocation,
        const LatLng(5.37, -4.03),
      );
    });

    test('markArrivedForRide prefers current realtime location', () async {
      notifier.syncRealtimeLocation(const LatLng(5.38, -4.04));

      await notifier.markArrivedForRide(
        _ride(
          id: '707',
          status: RideStatus.accepted,
          driverLocation: const LatLng(1, 1),
        ),
      );

      expect(repository.lastArrivedRideId, '707');
      expect(repository.lastArrivedLat, 5.38);
      expect(repository.lastArrivedLng, -4.04);
    });

    test('markArrivedForRide falls back to ride driver location', () async {
      await notifier.markArrivedForRide(
        _ride(
          id: '808',
          status: RideStatus.accepted,
          driverLocation: const LatLng(5.39, -4.05),
        ),
      );

      expect(repository.lastArrivedRideId, '808');
      expect(repository.lastArrivedLat, 5.39);
      expect(repository.lastArrivedLng, -4.05);
    });

    test('markArrivedForRide falls back to pickup location', () async {
      await notifier.markArrivedForRide(
        _ride(id: '909', status: RideStatus.accepted),
      );

      expect(repository.lastArrivedRideId, '909');
      expect(repository.lastArrivedLat, 5.4);
      expect(repository.lastArrivedLng, -3.9);
    });

    group('queued ride', () {
      // Brings the notifier to a state with queuedRide = 'new-ride' and
      // activeRide = 'active'. Uses the existing repository/notifier from
      // the outer setUp.
      Future<void> setupQueuedRide() async {
        repository.activeRide = _ride(
          id: 'active',
          status: RideStatus.inProgress,
        );
        repository.availableRides = [_ride(id: 'new-ride')];
        notifier.syncUserData(_approvedUserData);

        await notifier.setOnline(true);
        // Place driver exactly at the ride destination (0 m ≤ 1 000 m
        // threshold) so refreshHome triggers fetchAvailableRides = true.
        notifier.syncRealtimeLocation(const LatLng(5.32, -4.01));
        await notifier.refreshHome();

        // Simulate backend returning the accepted new ride after acceptance.
        repository.activeRide = _ride(
          id: 'new-ride',
          status: RideStatus.accepted,
        );
        await notifier.acceptRide('new-ride');
      }

      test(
        'acceptRide in pre-arrival mode sets queuedRide without overwriting activeRide',
        () async {
          repository.activeRide = _ride(
            id: 'active',
            status: RideStatus.inProgress,
          );
          repository.availableRides = [_ride(id: 'new-ride')];
          notifier.syncUserData(_approvedUserData);

          await notifier.setOnline(true);
          notifier.syncRealtimeLocation(const LatLng(5.32, -4.01));
          await notifier.refreshHome();

          expect(notifier.state.isPreArrivalOffersActive, isTrue);
          expect(notifier.state.activeRide?.rideId, 'active');

          repository.activeRide = _ride(
            id: 'new-ride',
            status: RideStatus.accepted,
          );
          final accepted = await notifier.acceptRide('new-ride');

          expect(accepted, isTrue);
          expect(notifier.state.activeRide?.rideId, 'active');
          expect(notifier.state.queuedRide?.rideId, 'new-ride');
          expect(notifier.state.isPreArrivalOffersActive, isFalse);
          expect(notifier.state.availableRides, isEmpty);
          expect(notifier.state.hasQueuedRide, isTrue);
          expect(notifier.state.canShowIncomingRequests, isFalse);
        },
      );

      test(
        'applyRealtimeRideStatus promotes queuedRide when active ride is cancelled',
        () async {
          await setupQueuedRide();

          await notifier.applyRealtimeRideStatus(
            DriverRideStatusRealtimeEvent(
              rideId: 'active',
              status: 'CANCELLED',
              updatedAt: DateTime(2026, 6, 25, 12),
              reason: 'Client a annule',
            ),
          );

          expect(notifier.state.activeRide?.rideId, 'new-ride');
          expect(notifier.state.queuedRide, isNull);
          expect(notifier.state.isPreArrivalOffersActive, isFalse);
          expect(notifier.state.availableRides, isEmpty);
        },
      );

      test('completeRide promotes queuedRide when active ride ends', () async {
        await setupQueuedRide();

        final success = await notifier.completeRide(
          rideId: 'active',
          finalDistanceKm: 7.0,
          finalDurationMin: 15,
          finalPrice: 2800,
        );

        expect(success, isTrue);
        expect(notifier.state.activeRide?.rideId, 'new-ride');
        expect(notifier.state.queuedRide, isNull);
        expect(notifier.state.isPreArrivalOffersActive, isFalse);
      });

      test('canShowIncomingRequests is false when queuedRide is set', () {
        final state = DriverHomeState(
          activeRide: _ride(id: 'a1', status: RideStatus.inProgress),
          queuedRide: _ride(id: 'q1'),
          isPreArrivalOffersActive: true,
        );

        expect(state.hasQueuedRide, isTrue);
        expect(state.canShowIncomingRequests, isFalse);
      });

      test('acceptRide is rejected when a queuedRide is already set', () async {
        await setupQueuedRide();

        final accepted = await notifier.acceptRide('another-ride');

        expect(accepted, isFalse);
        expect(notifier.state.queuedRide?.rideId, 'new-ride');
        expect(
          notifier.state.errorMessage,
          contains('Une autre course en attente'),
        );
      });
    });

    group('arrival detection', () {
      test(
        'emits a single arrival event once the driver enters the 30m radius',
        () async {
          repository.activeRide = _ride(
            id: 'arrival-1',
            status: RideStatus.inProgress,
          );
          notifier.syncUserData(_approvedUserData);
          await notifier.setOnline(true);

          // Destination des courses de test : LatLng(5.32, -4.01).
          notifier.syncRealtimeLocation(const LatLng(5.32, -4.01));
          notifier.evaluateArrivalDetection();

          expect(notifier.state.arrivalDetectionEvent, isNotNull);
          expect(notifier.state.arrivalDetectionEvent?.rideId, 'arrival-1');
        },
      );

      test(
        'does not re-emit while staying in zone before the cooldown elapses',
        () async {
          repository.activeRide = _ride(
            id: 'arrival-2',
            status: RideStatus.inProgress,
          );
          notifier.syncUserData(_approvedUserData);
          await notifier.setOnline(true);

          notifier.syncRealtimeLocation(const LatLng(5.32, -4.01));
          notifier.evaluateArrivalDetection();
          final firstEvent = notifier.state.arrivalDetectionEvent;
          expect(firstEvent, isNotNull);

          notifier.syncRealtimeLocation(const LatLng(5.32, -4.01));
          notifier.evaluateArrivalDetection();

          expect(
            notifier.state.arrivalDetectionEvent?.detectedAt,
            firstEvent!.detectedAt,
          );
        },
      );

      test('resets arrival tracking when a queued ride replaces the active '
          'ride (courses enchainees)', () async {
        repository.activeRide = _ride(
          id: 'chain-a',
          status: RideStatus.inProgress,
        );
        repository.availableRides = [_ride(id: 'chain-b')];
        notifier.syncUserData(_approvedUserData);
        await notifier.setOnline(true);

        // Le chauffeur entre dans la zone d'arrivee de la course A : cela
        // active aussi les offres de pre-arrivee (meme position que la
        // destination), ce qui permet d'accepter la course B en file.
        notifier.syncRealtimeLocation(const LatLng(5.32, -4.01));
        notifier.evaluateArrivalDetection();
        expect(notifier.state.arrivalDetectionEvent?.rideId, 'chain-a');
        await notifier.refreshHome();

        repository.activeRide = _ride(
          id: 'chain-b',
          status: RideStatus.accepted,
        );
        final accepted = await notifier.acceptRide('chain-b');
        expect(accepted, isTrue);
        expect(notifier.state.activeRide?.rideId, 'chain-a');
        expect(notifier.state.queuedRide?.rideId, 'chain-b');

        // La course A se termine ; le backend ne renvoie plus de course
        // active sous cet id, la course B en file est promue directement,
        // sans jamais repasser par activeRide == null.
        repository.activeRide = null;
        final success = await notifier.completeRide(
          rideId: 'chain-a',
          finalDistanceKm: 5.0,
          finalDurationMin: 10,
          finalPrice: 2000,
        );

        expect(success, isTrue);
        expect(notifier.state.activeRide?.rideId, 'chain-b');
        expect(notifier.state.activeRide?.status, RideStatus.accepted);
        expect(notifier.state.queuedRide, isNull);

        // La course B (accepted) ne declenche pas la modale d'arrivee :
        // le chauffeur roule vers le passager, pas vers la destination.
        expect(notifier.state.arrivalDetectionEvent?.rideId, 'chain-a');

        // Le chauffeur demarre la course B ; elle passe en inProgress.
        repository.activeRide = _ride(
          id: 'chain-b',
          status: RideStatus.inProgress,
        );
        final started = await notifier.startRide('chain-b');
        expect(started, isTrue);

        notifier.syncRealtimeLocation(const LatLng(5.32, -4.01));
        notifier.evaluateArrivalDetection();

        expect(notifier.state.arrivalDetectionEvent?.rideId, 'chain-b');
      });
    });
  });
}

const _approvedUserData = {
  'userId': 24,
  'driverId': 14,
  'kycStatus': 'APPROVED',
  'vehicleStatus': 'APPROVED',
  'vehicleId': 7,
};

final _approvedAuthState = AuthState(
  status: AuthStatus.authenticated,
  userData: _approvedUserData,
);

Future<void> _initLocalStorageForProviderTest() async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  await LocalStorage.instance.init();
}

Future<void> _waitUntilWalletLoaded(ProviderContainer container) async {
  for (var i = 0; i < 40; i++) {
    if (!container.read(driverWalletProvider).isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> _waitUntilWalletFetchCalls(
  RecordingDriverWalletRepository repository,
  int expectedCalls,
) async {
  for (var i = 0; i < 40; i++) {
    if (repository.fetchWalletOverviewCalls >= expectedCalls) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Position _position({required double latitude, required double longitude}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 1,
    altitudeAccuracy: 1,
    heading: 1,
    headingAccuracy: 1,
    speed: 1,
    speedAccuracy: 1,
  );
}

DriverRide _ride({
  required String id,
  RideStatus status = RideStatus.pending,
  LatLng? driverLocation,
}) {
  return DriverRide(
    rideId: id,
    status: status,
    passengerName: 'Alice Kouassi',
    pickupAddress: 'Cocody Angre',
    destinationAddress: 'Plateau Centre',
    pickupLocation: const LatLng(5.4, -3.9),
    destinationLocation: const LatLng(5.32, -4.01),
    requestedRange: 'MAGIC',
    estimatedPrice: 3200,
    estimatedDistanceKm: 8.4,
    estimatedDurationMin: 18,
    assignedDriverId: status == RideStatus.pending ? null : 14,
    vehicleId: status == RideStatus.pending ? null : 7,
    driverLocation: driverLocation,
    createdAt: DateTime(2026, 2, 24, 10),
    updatedAt: DateTime(2026, 2, 24, 10, 5),
  );
}
