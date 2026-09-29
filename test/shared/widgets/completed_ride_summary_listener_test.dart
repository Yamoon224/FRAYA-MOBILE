import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/shared/providers/app_providers.dart';
import 'package:fraya_mobile/shared/widgets/completed_ride_summary_listener.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
  });

  testWidgets('opens ride summary when a completed ride is stored', (
    tester,
  ) async {
    late GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CompletedRideSummaryListener(
            child: Scaffold(body: Text('Accueil')),
          ),
        ),
        GoRoute(
          path: RoutePaths.rideComplete,
          name: RouteNames.rideComplete,
          builder: (context, state) =>
              const Scaffold(body: Text('Résumé course')),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [appRouterProvider.overrideWithValue(router)],
    );
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    container
        .read(completedRideControllerProvider.notifier)
        .initialize(_completedRide);
    await tester.pumpAndSettle();

    expect(find.text('Résumé course'), findsOneWidget);
  });
}

const _completedRide = ActiveRide(
  rideId: 'ride_completed_123',
  driverName: 'Jean',
  driverPhoto: 'assets/images/driver_placeholder.png',
  driverRating: 4.8,
  carModel: 'Toyota Corolla',
  carPlate: 'AA-123-BB',
  destinationAddress: 'Plateau, Avenue Chardy',
  driverLocation: LatLng(5.35, -4.01),
  destinationLocation: LatLng(5.32, -4.00),
  status: RideStatus.completed,
  estimatedPrice: 3000,
);
