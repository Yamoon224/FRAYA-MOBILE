import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/error/failures.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/rate_ride.dart';

void main() {
  test('returns submitted outcome on successful repository call', () async {
    final repository = _FakeBookingRepository(
      outcome: RateRideOutcome.submitted,
    );
    final useCase = RateRideUseCase(repository);

    final result = await useCase(
      const RateRideParams(
        rideId: 'ride-1',
        rating: 5,
      ),
    );

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => RateRideOutcome.alreadySubmitted), RateRideOutcome.submitted);
  });

  test('returns alreadySubmitted outcome when repository maps duplicate', () async {
    final repository = _FakeBookingRepository(
      outcome: RateRideOutcome.alreadySubmitted,
    );
    final useCase = RateRideUseCase(repository);

    final result = await useCase(
      const RateRideParams(
        rideId: 'ride-2',
        rating: 4,
        comment: 'Bon trajet',
      ),
    );

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => RateRideOutcome.submitted), RateRideOutcome.alreadySubmitted);
  });

  test('maps ServerException into readable ServerFailure', () async {
    final repository = _FakeBookingRepository(
      error: const ServerException(message: 'database error', statusCode: 409),
    );
    final useCase = RateRideUseCase(repository);

    final result = await useCase(
      const RateRideParams(
        rideId: 'ride-3',
        rating: 5,
      ),
    );

    final failure = result.swap().getOrElse(
      () => const ServerFailure(message: 'unexpected'),
    );
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'database error');
  });
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({
    this.outcome = RateRideOutcome.submitted,
    this.error,
  });

  final RateRideOutcome outcome;
  final Object? error;

  @override
  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  }) async {
    if (error != null) throw error!;
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
