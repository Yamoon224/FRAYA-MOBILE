import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/core/services/home_navigation_notifier.dart';
import 'package:fraya_mobile/features/passenger/booking/models/booking_flow_state.dart';
import 'package:fraya_mobile/features/passenger/booking/screens/route_preview_screen_utils.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('active ride back goes home and requests search state reset', (
    tester,
  ) async {
    final notifier = HomeNavigationNotifier.instance;
    notifier.consumeResetSearchStateOnHomePending();
    notifier.consumeOpenDestinationSearchOnHomePending();

    final router = GoRouter(
      initialLocation: RoutePaths.vehicleSelection,
      routes: [
        GoRoute(
          path: RoutePaths.passengerHome,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: RoutePaths.vehicleSelection,
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => handleRoutePreviewBackPressed(
                  context,
                  flowState: BookingFlowState.driverAssigned,
                ),
                child: const Text('back'),
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(notifier.consumeResetSearchStateOnHomePending(), isTrue);
    expect(notifier.consumeOpenDestinationSearchOnHomePending(), isFalse);
  });
}
