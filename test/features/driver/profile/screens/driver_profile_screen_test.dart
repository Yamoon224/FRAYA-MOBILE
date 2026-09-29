import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/profile/screens/driver_profile_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  testWidgets('pull refresh refreshes the driver session profile', (
    tester,
  ) async {
    final authNotifier = FakeDriverAuthNotifier(
      AuthState(
        status: AuthStatus.authenticated,
        userData: const {
          'firstNames': 'Alice',
          'lastName': 'Kouassi',
          'phoneNumber': '+2250700000000',
          'email': 'alice@example.com',
        },
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [driverAuthProvider.overrideWith((ref) => authNotifier)],
        child: const MaterialApp(home: DriverProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice Kouassi'), findsOneWidget);
    expect(authNotifier.refreshProfileCalls, 0);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 360));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(authNotifier.refreshProfileCalls, 1);
  });
}
