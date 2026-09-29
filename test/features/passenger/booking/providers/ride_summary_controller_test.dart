import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/rate_ride.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_summary_controller.dart';

void main() {
  test('updateRating keeps rating when tapping same star again (no toggle)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(rideSummaryControllerProvider.notifier);
    controller.updateRating(4);
    expect(container.read(rideSummaryControllerProvider).rating, 4);

    // Tapping the same star again keeps the value (allowClear is false).
    controller.updateRating(4);
    expect(container.read(rideSummaryControllerProvider).rating, 4);
  });

  test('submitRating forwards trimmed comment and tip', () async {
    final repository = _FakeBookingRepository();
    final container = ProviderContainer(
      overrides: [
        rateRideUseCaseProvider.overrideWithValue(RateRideUseCase(repository)),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(rideSummaryControllerProvider.notifier);
    controller.updateRating(5);
    controller.updateComment('  Chauffeur tres pro  ');
    controller.updateTip(1500);

    final success = await controller.submitRating('ride-42');

    expect(success, isTrue);
    expect(repository.lastRideId, 'ride-42');
    expect(repository.lastRating, 5);
    expect(repository.lastComment, 'Chauffeur tres pro');
    expect(repository.lastTip, 1500.0);
    expect(container.read(rideSummaryControllerProvider).infoMessage, isNull);
  });

  test('submitRating keeps error when use case fails', () async {
    final repository = _FakeBookingRepository(shouldThrow: true);
    final container = ProviderContainer(
      overrides: [
        rateRideUseCaseProvider.overrideWithValue(RateRideUseCase(repository)),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(rideSummaryControllerProvider.notifier);
    controller.updateRating(3);
    controller.updateComment('Test');

    final success = await controller.submitRating('ride-1');
    final state = container.read(rideSummaryControllerProvider);

    expect(success, isFalse);
    expect(state.errorMessage, isNotNull);
    expect(state.infoMessage, isNull);
    expect(state.isSubmitting, isFalse);
  });

  test('submitRating blocks concurrent submissions', () async {
    final repository = _FakeBookingRepository(
      waitForCompletion: true,
    );
    final container = ProviderContainer(
      overrides: [
        rateRideUseCaseProvider.overrideWithValue(RateRideUseCase(repository)),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      rideSummaryControllerProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    final controller = container.read(rideSummaryControllerProvider.notifier);
    controller.updateRating(5);
    controller.updateComment('Course ok');

    final firstCall = controller.submitRating('ride-77');
    final secondCall = controller.submitRating('ride-77');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(repository.callCount, 1);
    expect(await secondCall, isFalse);

    repository.completePendingRequest();
    expect(await firstCall, isTrue);
  });

  test('submitRating sets infoMessage for already submitted outcome', () async {
    final repository = _FakeBookingRepository(
      rateRideOutcome: RateRideOutcome.alreadySubmitted,
    );
    final container = ProviderContainer(
      overrides: [
        rateRideUseCaseProvider.overrideWithValue(RateRideUseCase(repository)),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(rideSummaryControllerProvider.notifier);
    controller.updateRating(5);
    controller.updateComment('Excellent');

    final success = await controller.submitRating('ride-88');
    final state = container.read(rideSummaryControllerProvider);

    expect(success, isTrue);
    expect(state.errorMessage, isNull);
    expect(state.infoMessage, isNotNull);
  });
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({
    this.shouldThrow = false,
    this.waitForCompletion = false,
    this.rateRideOutcome = RateRideOutcome.submitted,
  });

  final bool shouldThrow;
  final bool waitForCompletion;
  final RateRideOutcome rateRideOutcome;
  int callCount = 0;
  String? lastRideId;
  int? lastRating;
  String? lastComment;
  double? lastTip;
  Completer<void>? _pendingCompleter;

  @override
  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  }) async {
    callCount++;
    if (waitForCompletion) {
      _pendingCompleter = Completer<void>();
      await _pendingCompleter!.future;
    }
    if (shouldThrow) {
      throw const ServerException(message: 'Erreur test');
    }
    lastRideId = rideId;
    lastRating = rating;
    lastComment = comment;
    lastTip = tip;
    return rateRideOutcome;
  }

  void completePendingRequest() {
    _pendingCompleter?.complete();
    _pendingCompleter = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
