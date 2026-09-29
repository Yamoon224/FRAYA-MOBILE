import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local/driver_onboarding_draft_local_data_source.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_onboarding_draft.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DriverOnboardingDraftLocalDataSource', () {
    late Directory tempDir;
    late DriverOnboardingDraftLocalDataSource dataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorage.instance.init();
      tempDir = await Directory.systemTemp.createTemp(
        'driver-onboarding-draft',
      );
      dataSource = DriverOnboardingDraftLocalDataSource(
        resolveBaseDirectory: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('persists a selected document inside the app directory', () async {
      final sourceFile = File('${tempDir.path}/source.pdf');
      await sourceFile.writeAsBytes(const [1, 2, 3]);

      final persisted = await dataSource.persistDocument(
        DriverKycDocumentFile.fromPath(
          path: sourceFile.path,
          fileName: 'source.pdf',
          source: DriverKycDocumentSource.pdfFile,
        )!,
        namespace: 'kyc_front',
      );

      expect(await File(persisted.path).exists(), isTrue);
      expect(
        persisted.path,
        contains(AppConstants.driverOnboardingDraftDirectory),
      );
    });

    test('saves, reads and clears the local draft with files', () async {
      final draftFile = File('${tempDir.path}/vehicle.png');
      await draftFile.writeAsBytes(const [4, 5, 6]);
      final persisted = await dataSource.persistDocument(
        DriverKycDocumentFile.fromPath(
          path: draftFile.path,
          fileName: 'vehicle.png',
          source: DriverKycDocumentSource.galleryImage,
        )!,
        namespace: 'vehicle_front',
      );
      final draft = DriverOnboardingDraft(
        kycDocuments: {
          DriverKycDocumentType.photoFrontPermis: _image(
            '/persisted/front.png',
            'front.png',
          ),
        },
        vehicleDocuments: {
          DriverVehicleDocumentType.photoFrontVehicle: persisted,
        },
        brand: 'Toyota',
        updatedAt: DateTime(2025),
      );

      await dataSource.saveDraft(draft);
      final restored = await dataSource.readDraft();

      expect(restored?.brand, 'Toyota');
      expect(
        restored
            ?.vehicleDocuments[DriverVehicleDocumentType.photoFrontVehicle]
            ?.path,
        persisted.path,
      );

      await dataSource.clearDraft();

      expect(await dataSource.readDraft(), isNull);
      expect(await File(persisted.path).exists(), isFalse);
    });

    test(
      'clearDraft removes orphan files when the draft is unreadable',
      () async {
        final draftDirectory = Directory(
          '${tempDir.path}/${AppConstants.driverOnboardingDraftDirectory}',
        );
        await draftDirectory.create(recursive: true);
        final orphan = File('${draftDirectory.path}/orphan.pdf');
        await orphan.writeAsBytes(const [7, 8, 9]);
        await LocalStorage.instance.setString(
          AppConstants.driverOnboardingDraftKey,
          '{invalid-json',
        );

        await dataSource.clearDraft();

        expect(await draftDirectory.exists(), isFalse);
        expect(
          LocalStorage.instance.getString(
            AppConstants.driverOnboardingDraftKey,
          ),
          isNull,
        );
      },
    );
  });
}

DriverKycDocumentFile _image(String path, String fileName) {
  return DriverKycDocumentFile.fromPath(
    path: path,
    fileName: fileName,
    source: DriverKycDocumentSource.galleryImage,
  )!;
}
