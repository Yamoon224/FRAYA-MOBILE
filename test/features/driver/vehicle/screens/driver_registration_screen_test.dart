import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/repositories/driver_kyc_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_vehicle_repository.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/kyc/providers/driver_kyc_dependencies.dart';
import 'package:fraya_mobile/features/driver/onboarding/providers/driver_onboarding_draft_dependencies.dart';
import 'package:fraya_mobile/features/driver/vehicle/providers/driver_vehicle_dependencies.dart';
import 'package:fraya_mobile/features/driver/vehicle/screens/driver_registration_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../support/driver_document_preparation_test_double.dart';
import '../../../../support/driver_test_doubles.dart';
import '../providers/driver_vehicle_provider_test_support.dart';

class _NoopKycRepository implements DriverKycRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _NoopVehicleRepository implements DriverVehicleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<void> _pump(WidgetTester tester, Map<String, dynamic> userData) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        driverAuthProvider.overrideWith(
          (ref) => FakeDriverAuthNotifier(
            AuthState(status: AuthStatus.authenticated, userData: userData),
          ),
        ),
        driverOnboardingDraftRepositoryProvider.overrideWithValue(
          InMemoryDriverOnboardingDraftRepository(),
        ),
        driverDocumentPreparationServiceProvider.overrideWithValue(
          PassthroughDriverDocumentPreparationService(),
        ),
        driverKycRepositoryProvider.overrideWithValue(_NoopKycRepository()),
        driverVehicleRepositoryProvider.overrideWithValue(
          _NoopVehicleRepository(),
        ),
      ],
      child: const MaterialApp(home: DriverRegistrationScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  const newDriver = {'driverId': 14, 'kycStatus': 'NOT_SUBMITTED'};

  testWidgets('affiche trois sections, la première ouverte par défaut', (tester) async {
    await _pump(tester, newDriver);

    expect(find.byKey(const ValueKey('accordion-driver-documents')), findsOneWidget);
    expect(find.byKey(const ValueKey('accordion-vehicle-info')), findsOneWidget);
    expect(find.byKey(const ValueKey('accordion-vehicle-documents')), findsOneWidget);

    // Première section ouverte : ses documents sont visibles ; les autres sont fermées.
    expect(find.byKey(const ValueKey('accordion-body-driver-documents')), findsOneWidget);
    expect(find.byKey(const ValueKey('accordion-body-vehicle-info')), findsNothing);
    expect(find.byKey(const ValueKey('accordion-body-vehicle-documents')), findsNothing);
  });

  testWidgets('ouvrir une section referme la précédente', (tester) async {
    await _pump(tester, newDriver);

    await tester.tap(find.byKey(const ValueKey('accordion-header-vehicle-info')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('accordion-body-vehicle-info')), findsOneWidget);
    expect(find.byKey(const ValueKey('accordion-body-driver-documents')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('accordion-header-vehicle-documents')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('accordion-body-vehicle-documents')), findsOneWidget);
    expect(find.byKey(const ValueKey('accordion-body-vehicle-info')), findsNothing);
  });

  testWidgets("le bouton d'envoi reste inactif et indique ce qu'il reste à compléter", (tester) async {
    await _pump(tester, newDriver);

    expect(find.text('Envoyer mon dossier'), findsOneWidget);
    final missing = tester.widget<Text>(find.byKey(const ValueKey('registration-missing')));
    expect(missing.data, contains('documents du chauffeur'));
    expect(missing.data, contains('informations du véhicule'));
    expect(missing.data, contains('documents du véhicule'));
  });

  testWidgets("reprise : si les documents du chauffeur sont déjà envoyés, la section est complète", (tester) async {
    await _pump(tester, const {'driverId': 14, 'kycStatus': 'PENDING_VALIDATION'});

    expect(find.byKey(const ValueKey('accordion-done-driver-documents')), findsOneWidget);
    final missing = tester.widget<Text>(find.byKey(const ValueKey('registration-missing')));
    expect(missing.data, isNot(contains('documents du chauffeur')));
  });
}
