import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';

void main() {
  group('RideStatus.fromBackend', () {
    test('maps pending-like statuses', () {
      expect(RideStatus.fromBackend('WAITING_DRIVER'), RideStatus.pending);
      expect(RideStatus.fromBackend('SEARCHING_DRIVER'), RideStatus.pending);
    });

    test('maps accepted-like statuses', () {
      expect(RideStatus.fromBackend('DRIVER_EN_ROUTE'), RideStatus.accepted);
      expect(RideStatus.fromBackend('CONFIRMED'), RideStatus.accepted);
    });

    test('maps arrived-like statuses', () {
      expect(RideStatus.fromBackend('AT_PICKUP'), RideStatus.arrived);
      expect(RideStatus.fromBackend('WAITING_FOR_PASSENGER'), RideStatus.arrived);
    });

    test('maps in-progress, completed and cancelled statuses', () {
      expect(RideStatus.fromBackend('TRIP_STARTED'), RideStatus.inProgress);
      expect(RideStatus.fromBackend('DONE'), RideStatus.completed);
      expect(RideStatus.fromBackend('ABORTED'), RideStatus.cancelled);
    });
  });
}
