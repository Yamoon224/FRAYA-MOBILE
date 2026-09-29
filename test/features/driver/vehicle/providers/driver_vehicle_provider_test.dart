import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_onboarding_draft.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';
import 'package:fraya_mobile/domain/usecases/driver/vehicle/submit_driver_vehicle_usecase.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_submission_review_info.dart';
import 'package:fraya_mobile/features/driver/vehicle/providers/driver_vehicle_provider.dart';
import 'driver_vehicle_provider_test_support.dart';
import '../../../../support/driver_document_preparation_test_double.dart';

void main() {
  group('DriverVehicleNotifier', () {
    late RecordingDriverVehicleRepository repository;
    late InMemoryDriverOnboardingDraftRepository draftRepository;
    late DriverVehicleNotifier notifier;
    Map<String, dynamic>? syncedResponse;

    setUp(() {
      repository = RecordingDriverVehicleRepository();
      draftRepository = InMemoryDriverOnboardingDraftRepository();
      syncedResponse = null;
      notifier = DriverVehicleNotifier(
        submitUseCase: SubmitDriverVehicleUseCase(repository),
        draftRepository: draftRepository,
        preparationService: PassthroughDriverDocumentPreparationService(),
        readDriverId: () => 9,
        readVehicleReviewData: () => null,
        syncVehicleSession: (response) async {
          syncedResponse = response;
          return null;
        },
      );
    });

    test(
      'stores supported documents, vehicle fields and persists draft',
      () async {
        await notifier.setDocument(
          DriverVehicleDocumentType.insuranceCertificate,
          pdfDocument('/tmp/insurance.pdf', 'insurance.pdf'),
        );
        notifier
          ..setBrand('Toyota')
          ..setModel('Corolla')
          ..setYear('2022')
          ..setColor('Rouge')
          ..setLicensePlate('AB-123-CD')
          ..setRange('elite');
        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.brand, 'Toyota');
        expect(notifier.state.selectedRange, 'ELITE');
        expect(
          notifier
              .state
              .documents[DriverVehicleDocumentType.insuranceCertificate]
              ?.path,
          '/persisted/vehicle_insuranceCertificate.pdf',
        );
        expect(draftRepository.draft?.brand, 'Toyota');
        expect(
          draftRepository.draft?.vehicleDocuments,
          contains(DriverVehicleDocumentType.insuranceCertificate),
        );
      },
    );

    test('restores saved draft on startup', () async {
      draftRepository.draft = DriverOnboardingDraft(
        brand: 'Toyota',
        model: 'Yaris',
        year: '2021',
        color: 'Gris',
        licensePlate: 'AA-101-AA',
        range: 'ELITE',
        vehicleDocuments: {
          DriverVehicleDocumentType.photoFrontVehicle: imageDocument(
            '/persisted/front.png',
            'front.png',
          ),
        },
        updatedAt: DateTime(2025),
      );
      draftRepository.existingPaths.add('/persisted/front.png');
      notifier = DriverVehicleNotifier(
        submitUseCase: SubmitDriverVehicleUseCase(repository),
        draftRepository: draftRepository,
        preparationService: PassthroughDriverDocumentPreparationService(),
        readDriverId: () => 9,
        readVehicleReviewData: () => null,
        syncVehicleSession: (_) async => null,
      );

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.brand, 'Toyota');
      expect(notifier.state.selectedRange, 'ELITE');
      expect(
        notifier.state.documents,
        contains(DriverVehicleDocumentType.photoFrontVehicle),
      );
    });

    test('drops missing vehicle documents when restoring a draft', () async {
      draftRepository.draft = DriverOnboardingDraft(
        brand: 'Toyota',
        vehicleDocuments: {
          DriverVehicleDocumentType.photoFrontVehicle: imageDocument(
            '/persisted/front.png',
            'front.png',
          ),
          DriverVehicleDocumentType.insuranceCertificate: imageDocument(
            '/persisted/missing-insurance.png',
            'missing-insurance.png',
          ),
        },
        updatedAt: DateTime(2025),
      );
      draftRepository.existingPaths.add('/persisted/front.png');

      notifier = DriverVehicleNotifier(
        submitUseCase: SubmitDriverVehicleUseCase(repository),
        draftRepository: draftRepository,
        preparationService: PassthroughDriverDocumentPreparationService(),
        readDriverId: () => 9,
        readVehicleReviewData: () => null,
        syncVehicleSession: (_) async => null,
      );

      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state.documents,
        contains(DriverVehicleDocumentType.photoFrontVehicle),
      );
      expect(
        notifier.state.documents,
        isNot(contains(DriverVehicleDocumentType.insuranceCertificate)),
      );
      expect(
        draftRepository.draft?.vehicleDocuments,
        isNot(contains(DriverVehicleDocumentType.insuranceCertificate)),
      );
    });

    test(
      'prefills rejected vehicle from session data when no draft exists',
      () async {
        notifier = DriverVehicleNotifier(
          submitUseCase: SubmitDriverVehicleUseCase(repository),
          draftRepository: draftRepository,
          preparationService: PassthroughDriverDocumentPreparationService(),
          readDriverId: () => 9,
          readVehicleReviewData: () => const DriverVehicleReviewData(
            brand: 'Hyundai',
            model: 'Accent',
            year: '2020',
            color: 'Blanc',
            licensePlate: 'AA-999-AA',
            range: 'elite',
          ),
          syncVehicleSession: (_) async => null,
        );

        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.brand, 'Hyundai');
        expect(notifier.state.model, 'Accent');
        expect(notifier.state.selectedRange, 'ELITE');
        expect(notifier.state.licensePlate, 'AA-999-AA');
      },
    );

    test('rejects unsupported document formats', () async {
      await notifier.setDocument(
        DriverVehicleDocumentType.vehicleRegistration,
        const DriverKycDocumentFile(
          path: '/tmp/carte_grise.docx',
          fileName: 'carte_grise.docx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          source: DriverKycDocumentSource.pdfFile,
        ),
      );

      expect(
        notifier.state.errorMessage,
        'Formats autorisés : PDF, JPG, JPEG ou PNG.',
      );
    });

    test(
      'blocks submit when required kyc documents are missing from draft',
      () async {
        await fillCompleteVehicleForm(notifier);

        await notifier.submit();

        expect(
          notifier.state.errorMessage,
          'Documents KYC manquants. Revenez à l\'étape KYC pour recharger les photos du permis.',
        );
        expect(repository.lastSubmission, isNull);
      },
    );

    test(
      'submits vehicle with aggregated kyc documents and clears draft',
      () async {
        draftRepository.draft = buildKycDraft();
        draftRepository.existingPaths.addAll(
          requiredKycTypes.map((type) => '/persisted/${type.name}.png'),
        );
        await fillCompleteVehicleForm(notifier);

        await notifier.submit();

        expect(repository.lastSubmission, isNotNull);
        expect(repository.lastSubmission?.sidUserId, 9);
        expect(repository.lastSubmission?.range, 'MAGIC');
        expect(
          repository.lastSubmission?.kycDocuments.keys.toSet(),
          requiredKycTypes.toSet(),
        );
        expect(syncedResponse?['id'], 17);
        expect(draftRepository.clearCalled, isTrue);
        expect(notifier.state.lastSubmittedAt, isNotNull);
        expect(notifier.state.errorMessage, isNull);
      },
    );

    test('submits rejected prefilled vehicle through create flow', () async {
      draftRepository.draft = buildKycDraft();
      draftRepository.existingPaths.addAll(
        requiredKycTypes.map((type) => '/persisted/${type.name}.png'),
      );
      final localNotifier = DriverVehicleNotifier(
        submitUseCase: SubmitDriverVehicleUseCase(repository),
        draftRepository: draftRepository,
        preparationService: PassthroughDriverDocumentPreparationService(),
        readDriverId: () => 9,
        readVehicleReviewData: () => const DriverVehicleReviewData(
          brand: 'Toyota',
          model: 'Corolla',
          year: '2022',
          color: 'Rouge',
          licensePlate: '12ERSTDFD',
          range: 'MAGIC',
        ),
        syncVehicleSession: (response) async {
          syncedResponse = response;
          return null;
        },
      );
      await Future<void>.delayed(Duration.zero);
      await fillCompleteVehicleForm(localNotifier);

      await localNotifier.submit();

      expect(repository.lastSubmission, isNotNull);
      expect(repository.lastSubmission?.brand, 'Toyota');
      expect(
        repository.lastSubmission?.documents.keys,
        contains(DriverVehicleDocumentType.vehicleRegistration),
      );
      expect(syncedResponse?['id'], 17);
      expect(draftRepository.clearCalled, isTrue);
      expect(localNotifier.state.lastSubmittedAt, isNotNull);
    });

    test('shows driver identification error when session is missing', () async {
      final localNotifier = DriverVehicleNotifier(
        submitUseCase: SubmitDriverVehicleUseCase(repository),
        draftRepository: draftRepository,
        preparationService: PassthroughDriverDocumentPreparationService(),
        readDriverId: () => null,
        readVehicleReviewData: () => null,
        syncVehicleSession: (_) async => null,
      );
      draftRepository.draft = buildKycDraft();
      draftRepository.existingPaths.addAll(
        requiredKycTypes.map((type) => '/persisted/${type.name}.png'),
      );
      await fillCompleteVehicleForm(localNotifier);

      await localNotifier.submit();

      expect(
        localNotifier.state.errorMessage,
        'Impossible d\'identifier le chauffeur connecté.',
      );
      expect(repository.lastSubmission, isNull);
    });

    test('surfaces missing local kyc file before API call', () async {
      draftRepository.draft = buildKycDraft();
      draftRepository.existingPaths.add('/persisted/photoFrontPermis.png');
      await fillCompleteVehicleForm(notifier);

      await notifier.submit();

      expect(
        notifier.state.errorMessage,
        'Le document permis - verso est introuvable sur l appareil. Rechargez-le depuis le KYC.',
      );
      expect(repository.lastSubmission, isNull);
    });

    test('surfaces missing local vehicle file before API call', () async {
      draftRepository.draft = buildKycDraft();
      draftRepository.existingPaths.addAll(
        requiredKycTypes.map((type) => '/persisted/${type.name}.png'),
      );
      await fillCompleteVehicleForm(notifier);
      draftRepository.existingPaths.remove(
        '/persisted/vehicle_insuranceCertificate.pdf',
      );

      await notifier.submit();

      expect(
        notifier.state.errorMessage,
        'Le document assurance véhicule est introuvable. Rechargez-le avant de continuer.',
      );
      expect(repository.lastSubmission, isNull);
    });

    test('surfaces session sync error after successful API submission', () async {
      final localNotifier = DriverVehicleNotifier(
        submitUseCase: SubmitDriverVehicleUseCase(repository),
        draftRepository: draftRepository,
        preparationService: PassthroughDriverDocumentPreparationService(),
        readDriverId: () => 9,
        readVehicleReviewData: () => null,
        syncVehicleSession: (_) async {
          return 'Le véhicule a été créé mais son identifiant est introuvable dans la réponse serveur.';
        },
      );
      draftRepository.draft = buildKycDraft();
      draftRepository.existingPaths.addAll(
        requiredKycTypes.map((type) => '/persisted/${type.name}.png'),
      );
      await fillCompleteVehicleForm(localNotifier);

      await localNotifier.submit();

      expect(
        localNotifier.state.errorMessage,
        'Le véhicule a été créé mais son identifiant est introuvable dans la réponse serveur.',
      );
      expect(localNotifier.state.lastSubmittedAt, isNull);
      expect(draftRepository.clearCalled, isFalse);
    });

    test('surfaces use case failures in french', () async {
      repository.error = const ValidationException(message: 'Plaque invalide.');
      draftRepository.draft = buildKycDraft();
      draftRepository.existingPaths.addAll(
        requiredKycTypes.map((type) => '/persisted/${type.name}.png'),
      );
      await fillCompleteVehicleForm(notifier);

      await notifier.submit();

      expect(notifier.state.errorMessage, 'Plaque invalide.');
      expect(notifier.state.lastSubmittedAt, isNull);
      expect(draftRepository.clearCalled, isFalse);
    });
  });
}
