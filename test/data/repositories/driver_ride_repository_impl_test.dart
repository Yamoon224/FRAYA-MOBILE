import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/repositories/driver_ride_repository_impl.dart';
import 'package:fraya_mobile/data/sources/remote/driver_ride_remote_data_source.dart';

class FakeDriverRideRemoteDataSource extends DriverRideRemoteDataSource {
  FakeDriverRideRemoteDataSource(this.rides) : super(dio: Dio());

  final List<Map<String, dynamic>> rides;

  @override
  Future<List<Map<String, dynamic>>> getAllRides() async => rides;

  @override
  Future<List<Map<String, dynamic>>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async => rides;
}

void main() {
  group('DriverRideRepositoryImpl', () {
    test('returns only pending unassigned rides sorted by recency', () async {
      final repository = DriverRideRepositoryImpl(
        remoteDataSource: FakeDriverRideRemoteDataSource([
          {
            'id': 1,
            'status': 'PENDING',
            'updatedAt': '2026-05-08T10:00:00.000Z',
          },
          {
            'id': 2,
            'status': 'ASSIGNED',
            'driverId': 7,
            'updatedAt': '2026-05-08T12:00:00.000Z',
          },
          {
            'id': 3,
            'status': 'PENDING',
            'driverId': 4,
            'updatedAt': '2026-05-08T13:00:00.000Z',
          },
          {
            'id': 4,
            'status': 'PENDING',
            'updatedAt': '2026-05-08T11:00:00.000Z',
          },
        ]),
      );

      final rides = await repository.getAvailableRides(
        lat: 5.35,
        lng: -4.01,
        radiusKm: 10,
      );

      expect(rides.map((ride) => ride.rideId).toList(), ['4', '1']);
    });

    test('selects the active ride assigned to the driver', () async {
      final repository = DriverRideRepositoryImpl(
        remoteDataSource: FakeDriverRideRemoteDataSource([
          {
            'id': 10,
            'status': 'ARRIVED',
            'driverId': 9,
            'updatedAt': '2026-05-08T14:00:00.000Z',
          },
          {
            'id': 11,
            'status': 'PENDING',
            'driverId': 9,
            'updatedAt': '2026-05-08T15:00:00.000Z',
          },
        ]),
      );

      final ride = await repository.getActiveRide(9);

      expect(ride?.rideId, '10');
    });

    test(
      'returns historical rides sorted by completion or cancellation date',
      () async {
        final repository = DriverRideRepositoryImpl(
          remoteDataSource: FakeDriverRideRemoteDataSource([
            {
              'id': 21,
              'status': 'COMPLETED',
              'dateArrival': '2026-05-08T09:00:00.000Z',
            },
            {
              'id': 22,
              'status': 'CANCELLED_DRIVER',
              'dateCancellation': '2026-05-08T11:00:00.000Z',
            },
            {
              'id': 23,
              'status': 'IN_PROGRESS',
              'updatedAt': '2026-05-08T12:00:00.000Z',
            },
          ]),
        );

        final rides = await repository.getHistoryRides();

        expect(rides.map((ride) => ride.rideId).toList(), ['22', '21']);
      },
    );
  });
}
