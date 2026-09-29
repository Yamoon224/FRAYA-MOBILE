import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/accept_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/cancel_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/complete_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/get_driver_active_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/mark_driver_ride_arrived.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/start_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/status/update_driver_status.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_notifier.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_state.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  group('DriverHomeNotifier stabilization', () {
    late FakeDriverRideRepository repository;
    late DriverHomeNotifier notifier;

    setUp(() {
      repository = FakeDriverRideRepository();
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
        updateDriverStatusUseCase: UpdateDriverStatusUseCase(
          FakeDriverStatusRepository(),
        ),
      );
    });

    tearDown(() {
      notifier.dispose();
    });

    test(
      'accept conflict keeps list synchronized and exposes a french message',
      () async {
        repository.availableRides = [buildDriverRide(id: '303')];
        notifier.syncUserData(_approvedUserData);
        await notifier.setOnline(true);
        repository.acceptRideError = const ServerException(
          message:
              'Cette course n\'est plus disponible. Actualisez la liste des demandes.',
        );

        final success = await notifier.acceptRide('303');

        expect(success, isFalse);
        expect(notifier.state.status, DriverHomeStatus.ready);
        expect(notifier.state.availableRides, hasLength(1));
        expect(notifier.state.isSubmittingAction, isFalse);
        expect(
          notifier.state.errorMessage,
          'Cette course n\'est plus disponible. Actualisez la liste des demandes.',
        );
      },
    );

    test(
      'refresh keeps visible active ride state when backend refresh fails',
      () async {
        repository.activeRide = buildDriverRide(
          id: '404',
          status: RideStatus.accepted,
        );
        notifier.syncUserData(_approvedUserData);
        await notifier.setOnline(true);
        repository.activeRideError = const ServerException(
          message: 'Reseau indisponible.',
        );

        await notifier.refreshHome();

        expect(notifier.state.status, DriverHomeStatus.ready);
        expect(notifier.state.activeRide?.rideId, '404');
        expect(notifier.state.errorMessage, 'Reseau indisponible.');
      },
    );

    test(
      'rejects missing driverId, vehicleId and empty ride ids before repository calls',
      () async {
        notifier.syncUserData(const {
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
          'vehicleId': 7,
        });
        expect(await notifier.acceptRide('101'), isFalse);

        notifier.syncUserData(const {
          'driverId': 14,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
        });
        expect(await notifier.acceptRide('101'), isFalse);
        expect(await notifier.acceptRide('   '), isFalse);
        expect(await notifier.startRide('   '), isFalse);
        expect(
          await notifier.completeRide(
            rideId: '   ',
            finalDistanceKm: 1,
            finalDurationMin: 1,
            finalPrice: 1000,
          ),
          isFalse,
        );
        expect(
          await notifier.cancelRide(rideId: '   ', reason: 'test'),
          isFalse,
        );
        expect(
          await notifier.markArrived(
            rideId: '   ',
            driverLat: 5.36,
            driverLng: -4.02,
          ),
          isFalse,
        );
        expect(repository.acceptRideCalls, 0);
        expect(repository.startRideCalls, 0);
        expect(repository.completeRideCalls, 0);
        expect(repository.cancelRideCalls, 0);
        expect(repository.markArrivedCalls, 0);
        expect(notifier.state.errorMessage, 'Course introuvable.');
      },
    );

    test(
      'keeps a coherent ready state after critical action backend errors',
      () async {
        final actions = <Future<bool> Function()>[
          () async {
            repository.activeRide = buildDriverRide(
              id: '1',
              status: RideStatus.accepted,
            );
            repository.markArrivedError = const ServerException(
              message: 'Arrivee impossible.',
            );
            return notifier.markArrivedForRide(repository.activeRide!);
          },
          () async {
            repository.activeRide = buildDriverRide(
              id: '2',
              status: RideStatus.arrived,
            );
            repository.startRideError = const ServerException(
              message: 'Demarrage impossible.',
            );
            return notifier.startRide('2');
          },
          () async {
            repository.activeRide = buildDriverRide(
              id: '3',
              status: RideStatus.inProgress,
            );
            repository.completeRideError = const ServerException(
              message: 'Cloture impossible.',
            );
            return notifier.completeRide(
              rideId: '3',
              finalDistanceKm: 8.4,
              finalDurationMin: 18,
              finalPrice: 3200,
            );
          },
          () async {
            repository.activeRide = buildDriverRide(
              id: '4',
              status: RideStatus.accepted,
            );
            repository.cancelRideError = const ServerException(
              message: 'Annulation impossible.',
            );
            return notifier.cancelRide(rideId: '4', reason: 'test');
          },
        ];
        notifier.syncUserData(_approvedUserData);
        await notifier.setOnline(true);

        for (final action in actions) {
          final success = await action();
          expect(success, isFalse);
          expect(notifier.state.status, DriverHomeStatus.ready);
          expect(notifier.state.isSubmittingAction, isFalse);
          expect(notifier.state.errorMessage, isNotEmpty);
          repository.markArrivedError = null;
          repository.startRideError = null;
          repository.completeRideError = null;
          repository.cancelRideError = null;
        }
      },
    );
  });
}

const _approvedUserData = {
  'userId': 24,
  'driverId': 14,
  'kycStatus': 'APPROVED',
  'vehicleStatus': 'APPROVED',
  'vehicleId': 7,
};
