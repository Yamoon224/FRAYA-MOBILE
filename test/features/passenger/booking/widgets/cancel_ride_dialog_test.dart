import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/cancel_ride_dialog.dart';

class _ResettableBookingFlow extends BookingFlow {
  static bool resetCalled = false;

  @override
  BookingFlowState build() => BookingFlowState.searching;

  @override
  void reset() {
    resetCalled = true;
    state = BookingFlowState.idle;
  }
}

class _CancelRideDialogTrigger extends ConsumerWidget {
  const _CancelRideDialogTrigger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => CancelRideDialog.show(context, ref),
      child: const Text('open'),
    );
  }
}

void main() {
  testWidgets(
    'cancel ride dialog shows primary action above secondary action',
    (tester) async {
      _ResettableBookingFlow.resetCalled = false;
      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_ResettableBookingFlow.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: _CancelRideDialogTrigger()),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Annuler la course ?'), findsOneWidget);
      _expectAbove(tester, find.text('Annuler'), find.text('Garder la course'));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Garder la course'));
      await tester.pumpAndSettle();
      expect(_ResettableBookingFlow.resetCalled, isFalse);
    },
  );

  testWidgets('cancel ride dialog primary action resets booking flow', (
    tester,
  ) async {
    _ResettableBookingFlow.resetCalled = false;
    final container = ProviderContainer(
      overrides: [bookingFlowProvider.overrideWith(_ResettableBookingFlow.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: _CancelRideDialogTrigger()),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Annuler'));
    await tester.pumpAndSettle();

    expect(_ResettableBookingFlow.resetCalled, isTrue);
  });
}

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}
