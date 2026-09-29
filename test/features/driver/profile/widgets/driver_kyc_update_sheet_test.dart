import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/profile/providers/driver_kyc_update_state.dart';
import 'package:fraya_mobile/features/driver/profile/widgets/driver_kyc_update_sheet.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  testWidgets('shows personal KYC update documents accepted by the backend', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverAuthProvider.overrideWith(
            (ref) => FakeDriverAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                userData: const {'id': 37, 'kycStatus': 'REJECTED'},
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DriverKycUpdateSheet(kycId: 6)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(DriverKycDocumentType.photoFrontPermis.label),
      findsOneWidget,
    );
    expect(
      find.text(DriverKycDocumentType.photoBackPermis.label),
      findsOneWidget,
    );
    expect(
      find.text(DriverKycDocumentType.photoSelfPermis.label),
      findsOneWidget,
    );
    expect(find.text(DriverKycDocumentType.photoCasier.label), findsOneWidget);
    expect(
      find.text(DriverKycDocumentType.insuranceCertificate.label),
      findsNothing,
    );
    expect(
      find.text(DriverKycDocumentType.vehicleRegistration.label),
      findsNothing,
    );
  });

  testWidgets('vehicle mode shows vehicle documents without submit action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverAuthProvider.overrideWith(
            (ref) => FakeDriverAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                userData: const {'id': 37, 'kycStatus': 'APPROVED'},
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DriverKycUpdateSheet(
              kycId: 6,
              documentGroup: DriverKycUpdateDocumentGroup.vehicle,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Documents véhicule'), findsWidgets);
    for (final type in driverKycVehicleDocuments) {
      final finder = find.text(type.label);
      await tester.scrollUntilVisible(finder, 160);
      expect(finder, findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Confirmer la mise à jour'), 160);
    expect(find.text('Confirmer la mise à jour'), findsOneWidget);
    expect(find.text('Mise à jour bientôt disponible'), findsNothing);
  });
}
