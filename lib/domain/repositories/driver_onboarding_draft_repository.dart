library;

import '../models/driver_kyc_document_file.dart';
import '../models/driver_onboarding_draft.dart';

abstract class DriverOnboardingDraftRepository {
  Future<DriverOnboardingDraft?> readDraft();

  Future<void> saveDraft(DriverOnboardingDraft draft);

  Future<void> clearDraft();

  Future<DriverKycDocumentFile> persistDocument(
    DriverKycDocumentFile file, {
    required String namespace,
  });

  Future<void> removePersistedDocument(String path);

  Future<bool> documentExists(String path);
}
