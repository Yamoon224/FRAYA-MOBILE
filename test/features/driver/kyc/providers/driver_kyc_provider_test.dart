import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_submission.dart';
import 'package:fraya_mobile/domain/models/driver_onboarding_draft.dart';
import 'package:fraya_mobile/domain/repositories/driver_kyc_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_onboarding_draft_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/kyc/submit_driver_kyc_usecase.dart';
import 'package:fraya_mobile/features/driver/kyc/providers/driver_kyc_dependencies.dart';
import 'package:fraya_mobile/features/driver/kyc/providers/driver_kyc_provider.dart';
import 'package:fraya_mobile/features/driver/onboarding/providers/driver_onboarding_draft_dependencies.dart';

import '../../../../support/driver_document_preparation_test_double.dart';

class NoopDriverKycRepository implements DriverKycRepository {
  @override
  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required DriverKycSubmission submission,
  }) async {
    return const {};
  }

  @override
  Future<Map<String, dynamic>> updateKyc({
    required int kycId,
    required Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  }) async {
    return const {};
  }

  @override
  Future<Map<String, dynamic>> getKycBySidUser({required int sidUserId}) async {
    return const {'data': []};
  }
}

class InMemoryDriverOnboardingDraftRepository
    implements DriverOnboardingDraftRepository {
  DriverOnboardingDraft? draft;

  @override
  Future<DriverOnboardingDraft?> readDraft() async => draft;

  @override
  Future<void> saveDraft(DriverOnboardingDraft draft) async {
    this.draft = draft;
  }

  @override
  Future<void> clearDraft() async {
    draft = null;
  }

  @override
  Future<DriverKycDocumentFile> persistDocument(
    DriverKycDocumentFile file, {
    required String namespace,
  }) async {
    final extension = file.fileName.endsWith('.png') ? '.png' : '.pdf';
    return DriverKycDocumentFile(
      path: '/persisted/$namespace$extension',
      fileName: file.fileName,
      mimeType: file.mimeType,
      source: file.source,
    );
  }

  @override
  Future<void> removePersistedDocument(String path) async {}

  @override
  Future<bool> documentExists(String path) async => true;
}

void main() {
  group('DriverKycNotifier', () {
    late InMemoryDriverOnboardingDraftRepository draftRepository;
    late ProviderContainer container;

    setUp(() {
      draftRepository = InMemoryDriverOnboardingDraftRepository();
      container = ProviderContainer(
        overrides: [
          driverOnboardingDraftRepositoryProvider.overrideWithValue(
            draftRepository,
          ),
          submitDriverKycUseCaseProvider.overrideWithValue(
            SubmitDriverKycUseCase(NoopDriverKycRepository()),
          ),
          driverDocumentPreparationServiceProvider.overrideWithValue(
            PassthroughDriverDocumentPreparationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('persists selected document into onboarding draft', () async {
      final notifier = container.read(driverKycFormProvider.notifier);

      await notifier.setDocument(
        DriverKycDocumentType.photoFrontPermis,
        _image('/tmp/front.png', 'front.png'),
      );

      final state = container.read(driverKycFormProvider);
      expect(
        state.documents[DriverKycDocumentType.photoFrontPermis]?.path,
        '/persisted/kyc_photoFrontPermis.png',
      );
      expect(
        draftRepository.draft?.kycDocuments,
        contains(DriverKycDocumentType.photoFrontPermis),
      );
    });

    test(
      'restores saved draft and removes documents from draft state',
      () async {
        draftRepository.draft = DriverOnboardingDraft(
          kycDocuments: {
            DriverKycDocumentType.photoBackPermis: _image(
              '/persisted/back.png',
              'back.png',
            ),
          },
          updatedAt: DateTime(2025),
        );
        final localContainer = ProviderContainer(
          overrides: [
            driverOnboardingDraftRepositoryProvider.overrideWithValue(
              draftRepository,
            ),
            submitDriverKycUseCaseProvider.overrideWithValue(
              SubmitDriverKycUseCase(NoopDriverKycRepository()),
            ),
            driverDocumentPreparationServiceProvider.overrideWithValue(
              PassthroughDriverDocumentPreparationService(),
            ),
          ],
        );
        addTearDown(localContainer.dispose);

        await Future<void>.delayed(Duration.zero);
        final notifier = localContainer.read(driverKycFormProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(
          localContainer.read(driverKycFormProvider).documents,
          contains(DriverKycDocumentType.photoBackPermis),
        );

        await notifier.removeDocument(DriverKycDocumentType.photoBackPermis);

        expect(
          localContainer.read(driverKycFormProvider).documents,
          isNot(contains(DriverKycDocumentType.photoBackPermis)),
        );
        expect(draftRepository.draft?.kycDocuments, isEmpty);
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
