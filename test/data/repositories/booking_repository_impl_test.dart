import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/repositories/booking_repository_impl.dart';
import 'package:fraya_mobile/data/sources/remote/booking_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/ride_share_link.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';

class FakeBookingRemoteDataSource extends BookingRemoteDataSource {
  FakeBookingRemoteDataSource({
    this.activeRide,
    this.userRides = const [],
    this.activeRideError,
    this.pricingResponse,
    this.rateRideResult = RateRideOutcome.submitted,
    this.rideShareLink = const RideShareLink(
      token: 'share-token',
      url: 'https://manager.frayataxi.ci/ride/tracking/share-token',
      expiresAt: null,
      isValid: true,
    ),
  }) : super(dio: Dio());

  final Map<String, dynamic>? activeRide;
  final List<Map<String, dynamic>> userRides;
  final Object? activeRideError;
  final Map<String, dynamic>? pricingResponse;
  final RateRideOutcome rateRideResult;
  final RideShareLink rideShareLink;
  String? capturedRideId;
  int? capturedRating;
  String? capturedComment;
  double? capturedTip;
  int? capturedExpiresIn;

  @override
  Future<Map<String, dynamic>> calculatePrices(
    CalculateRidePricesParams params,
  ) async {
    return pricingResponse ?? const {};
  }

  @override
  Future<Map<String, dynamic>?> getActiveRide(int userId) async {
    if (activeRideError != null) throw activeRideError!;
    return activeRide;
  }

  @override
  Future<List<Map<String, dynamic>>> getUserRides(int userId) async => userRides;

  @override
  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  }) async {
    capturedRideId = rideId;
    capturedRating = rating;
    capturedComment = comment;
    capturedTip = tip;
    return rateRideResult;
  }

  @override
  Future<RideShareLink> createRideShareLink({
    required String rideId,
    int expiresIn = 60,
  }) async {
    capturedRideId = rideId;
    capturedExpiresIn = expiresIn;
    return rideShareLink;
  }
}

void main() {
  test('parses nested estimate prices and amount received aliases', () async {
    final repository = BookingRepositoryImpl(
      remoteDataSource: FakeBookingRemoteDataSource(
        pricingResponse: {
          'success': true,
          'data': {
            'message': 'Course calculee avec succes',
            'data': {
              'prices': [
                {
                  'range': 'MAGIC',
                  'totalPrice': 5700,
                  'amountReceved': 5200,
                },
                {
                  'range': 'GLADIATEUR',
                  'totalPrice': '6600',
                  'amountReceived': '6100',
                },
                {'range': 'ELITE', 'totalPrice': 8600},
              ],
            },
          },
        },
      ),
    );

    final prices = await repository.calculateRidePrices(
      const CalculateRidePricesParams(
        latDeparture: 5.39,
        longDeparture: -3.97,
        arrivalPlaceId: 'destination_place_id',
        arrivalLat: 5.26,
        arrivalLong: -3.94,
      ),
    );

    expect(prices['MAGIC']?.totalPrice, 5700);
    expect(prices['MAGIC']?.amountReceived, 5200);
    expect(prices['GLADIATEUR']?.amountReceived, 6100);
    expect(prices['ELITE']?.amountReceived, 8600);
  });

  group('BookingRepositoryImpl.getActiveRide', () {
    test('returns the active ride endpoint payload when available', () async {
      final repository = BookingRepositoryImpl(
        remoteDataSource: FakeBookingRemoteDataSource(
          activeRide: {
            'id': 55,
            'status': 'ACCEPTED',
            'departureAddress': 'Cocody',
            'arrivalAddress': 'Plateau',
          },
        ),
      );

      final ride = await repository.getActiveRide(8);

      expect(ride?.rideId, '55');
      expect(ride?.pickupAddress, 'Cocody');
    });

    test('falls back to user rides when /active returns null', () async {
      final repository = BookingRepositoryImpl(
        remoteDataSource: FakeBookingRemoteDataSource(
          activeRide: null,
          userRides: [
            {
              'id': 1,
              'status': 'COMPLETED',
              'updatedAt': '2026-05-08T08:00:00.000Z',
            },
            {
              'id': 2,
              'status': 'SEARCHING',
              'updatedAt': '2026-05-08T10:00:00.000Z',
            },
          ],
        ),
      );

      final ride = await repository.getActiveRide(8);

      expect(ride?.rideId, '2');
      expect(ride?.status.name, 'pending');
    });

    test('falls back to user rides when /active throws a server error', () async {
      final repository = BookingRepositoryImpl(
        remoteDataSource: FakeBookingRemoteDataSource(
          activeRideError: const ServerException(message: 'invalid payload'),
          userRides: [
            {
              'id': 11,
              'status': 'ARRIVED',
              'updatedAt': '2026-05-08T12:00:00.000Z',
            },
          ],
        ),
      );

      final ride = await repository.getActiveRide(8);

      expect(ride?.rideId, '11');
      expect(ride?.status.name, 'arrived');
    });

    test('selects the requested ride id from user rides first', () async {
      final repository = BookingRepositoryImpl(
        remoteDataSource: FakeBookingRemoteDataSource(
          activeRide: {
            'id': 999,
            'status': 'SEARCHING',
          },
          userRides: [
            {'id': 70, 'status': 'COMPLETED'},
            {'rideId': 'ABC-1', 'status': 'IN_PROGRESS'},
          ],
        ),
      );

      final ride = await repository.getActiveRide(8, rideId: 'ABC-1');

      expect(ride?.rideId, 'ABC-1');
      expect(ride?.status.name, 'inProgress');
    });

    test('returns null when there is no active ride anywhere', () async {
      final repository = BookingRepositoryImpl(
        remoteDataSource: FakeBookingRemoteDataSource(
          activeRide: null,
          userRides: const [
            {'id': 1, 'status': 'COMPLETED'},
            {'id': 2, 'status': 'CANCELLED'},
          ],
        ),
      );

      final ride = await repository.getActiveRide(8);

      expect(ride, isNull);
    });
  });

  test('rateRide delegates parameters to remote data source', () async {
    final dataSource = FakeBookingRemoteDataSource();
    final repository = BookingRepositoryImpl(remoteDataSource: dataSource);

    final success = await repository.rateRide(
      rideId: '777',
      rating: 5,
      comment: 'Super',
      tip: 500.0,
    );

    expect(success, RateRideOutcome.submitted);
    expect(dataSource.capturedRideId, '777');
    expect(dataSource.capturedRating, 5);
    expect(dataSource.capturedComment, 'Super');
    expect(dataSource.capturedTip, 500.0);
  });

  test('createRideShareLink delegates parameters to remote data source', () async {
    final dataSource = FakeBookingRemoteDataSource();
    final repository = BookingRepositoryImpl(remoteDataSource: dataSource);

    final link = await repository.createRideShareLink(
      rideId: '88',
      expiresIn: 60,
    );

    expect(dataSource.capturedRideId, '88');
    expect(dataSource.capturedExpiresIn, 60);
    expect(link.url, contains('/ride/tracking/'));
  });
}
