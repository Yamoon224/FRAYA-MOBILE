import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/vehicle/screens/driver_vehicle_pending_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  testWidgets('renders a waiting page without vehicle form fields', (
    tester,
  ) async {
    await _pumpPendingScreen(tester);

    expect(find.text('Dossier en cours de validation'), findsOneWidget);
    expect(find.text('Actualiser le statut'), findsOneWidget);
    expect(find.text('Dossier KYC'), findsOneWidget);
    expect(find.text('Dossier véhicule'), findsOneWidget);
    expect(find.text('En attente'), findsWidgets);
    expect(find.text('Informations du véhicule'), findsNothing);
    expect(find.text('Documents véhicule'), findsNothing);
  });

  testWidgets('refresh indicator asks auth provider to refresh profile', (
    tester,
  ) async {
    final authNotifier = await _pumpPendingScreen(tester);

    final refreshIndicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refreshIndicator.onRefresh();
    await tester.pump();

    expect(authNotifier.refreshProfileCalls, 1);
  });
}

Future<FakeDriverAuthNotifier> _pumpPendingScreen(WidgetTester tester) async {
  final authNotifier = FakeDriverAuthNotifier(
    AuthState(
      status: AuthStatus.authenticated,
      userData: const {
        'driverId': 14,
        'kycStatus': 'PENDING_VALIDATION',
        'vehicleStatus': 'PENDING_VALIDATION',
        'vehicleId': 7,
      },
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [driverAuthProvider.overrideWith((ref) => authNotifier)],
      child: const MaterialApp(home: DriverVehiclePendingScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return authNotifier;
}
