import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/rate_ride.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_summary_controller.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/ride_summary/ride_summary_actions.dart';
import 'package:fraya_mobile/shared/widgets/fraya_button.dart';

void main() {
  testWidgets('shows loading spinner and disables submit while submitting', (
    tester,
  ) async {
    final repository = _FakeBookingRepository(waitForCompletion: true);
    final container = ProviderContainer(
      overrides: [
        rateRideUseCaseProvider.overrideWithValue(RateRideUseCase(repository)),
      ],
    );
    addTearDown(container.dispose);

    container.read(rideSummaryControllerProvider.notifier).updateRating(5);

    var finishCalls = 0;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: RideSummaryActions(
              rideId: 'ride-901',
              onFinish: () => finishCalls++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Terminer'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FrayaButton>(find.byType(FrayaButton));
    expect(button.isLoading, isTrue);
    expect(finishCalls, 0);

    repository.completePendingRequest();
    await tester.pumpAndSettle();

    expect(finishCalls, 1);
  });

  testWidgets('continues flow when rating is already submitted', (
    tester,
  ) async {
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
    controller.updateRating(4);
    controller.updateComment('Bon trajet');

    var finishCalls = 0;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: RideSummaryActions(
              rideId: 'ride-902',
              onFinish: () => finishCalls++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(repository.callCount, 1);
    expect(finishCalls, 1);
    expect(find.text('Votre avis a déjà été pris en compte.'), findsOneWidget);
  });

  testWidgets('does not finish flow when rating submission fails', (
    tester,
  ) async {
    final repository = _FakeBookingRepository(shouldThrow: true);
    final container = ProviderContainer(
      overrides: [
        rateRideUseCaseProvider.overrideWithValue(RateRideUseCase(repository)),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(rideSummaryControllerProvider.notifier);
    controller.updateRating(4);
    controller.updateComment('Bon trajet');

    var finishCalls = 0;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: RideSummaryActions(
              rideId: 'ride-903',
              onFinish: () => finishCalls++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(repository.callCount, 1);
    expect(finishCalls, 0);
    expect(find.textContaining('Erreur test'), findsOneWidget);
  });
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({
    this.waitForCompletion = false,
    this.rateRideOutcome = RateRideOutcome.submitted,
    this.shouldThrow = false,
  });

  final bool waitForCompletion;
  final RateRideOutcome rateRideOutcome;
  final bool shouldThrow;
  int callCount = 0;
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
    return rateRideOutcome;
  }

  void completePendingRequest() {
    _pendingCompleter?.complete();
    _pendingCompleter = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
