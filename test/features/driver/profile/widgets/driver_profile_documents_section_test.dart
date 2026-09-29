import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/features/driver/profile/models/driver_profile_view_data.dart';
import 'package:fraya_mobile/features/driver/profile/widgets/driver_profile_documents_section.dart';

void main() {
  testWidgets('groups personal and vehicle documents without identity card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverProfileDocumentsSection(
            documents: const [
              DriverProfileDocumentViewData(
                type: DriverKycDocumentType.photoSelfPermis,
                section: DriverKycDocumentSection.driver,
                label: 'Selfie avec permis',
                expiryLabel: 'N/A',
                statusLabel: 'Valide',
                status: DriverProfileDocumentStatus.valid,
              ),
              DriverProfileDocumentViewData(
                type: DriverKycDocumentType.photoFrontVehicle,
                section: DriverKycDocumentSection.vehicle,
                label: 'Photo avant du véhicule',
                expiryLabel: 'N/A',
                statusLabel: 'Valide',
                status: DriverProfileDocumentStatus.valid,
              ),
            ],
            onUpdateTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Documents personnels'), findsOneWidget);
    expect(find.text('Documents véhicule'), findsOneWidget);
    expect(find.text('Selfie avec permis'), findsOneWidget);
    expect(find.text('Photo avant du véhicule'), findsOneWidget);
    expect(find.textContaining('ident'), findsNothing);
    expect(find.text('Mettre à jour mes documents'), findsOneWidget);
  });
}
