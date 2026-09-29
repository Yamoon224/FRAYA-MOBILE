import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/cancel_ride_sheet.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/sos_reason_sheet.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/ride_summary/report_problem_sheet.dart';

class _CapturingSearchingFlow extends BookingFlow {
  static String? lastCancelReason;

  @override
  BookingFlowState build() => BookingFlowState.searching;

  @override
  Future<void> cancelSearching({String? reason}) async {
    lastCancelReason = reason;
    state = BookingFlowState.routePreview;
  }
}

void main() {
  Future<void> pumpSheet(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(alignment: Alignment.bottomCenter, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cancel ride sheet stays scrollable on narrow screens', (
    tester,
  ) async {
    await pumpSheet(tester, const CancelRideSheet());

    expect(find.text('Raison d\'annulation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel ride sheet forwards selected reason to booking flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        bookingFlowProvider.overrideWith(_CapturingSearchingFlow.new),
      ],
    );
    addTearDown(container.dispose);
    _CapturingSearchingFlow.lastCancelReason = null;
    container.read(bookingFlowProvider.notifier);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: CancelRideSheet(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Attente trop longue'));
    await tester.pump();
    await tester.tap(find.text('Confirmer l\'annulation'));
    await tester.pump();

    expect(_CapturingSearchingFlow.lastCancelReason, 'Attente trop longue');
  });

  testWidgets('sos reason sheet stays scrollable on narrow screens', (
    tester,
  ) async {
    await pumpSheet(tester, const SosReasonSheet(rideId: 'ride-1'));

    expect(find.text('Type d\'urgence'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report problem sheet stays scrollable on narrow screens', (
    tester,
  ) async {
    await pumpSheet(tester, const ReportProblemSheet(rideId: 'ride-1'));

    expect(find.text('Signaler un probleme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
