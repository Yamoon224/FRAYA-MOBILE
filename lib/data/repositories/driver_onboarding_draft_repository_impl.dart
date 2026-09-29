library;

import '../../domain/models/driver_kyc_document_file.dart';
import '../../domain/models/driver_onboarding_draft.dart';
import '../../domain/repositories/driver_onboarding_draft_repository.dart';
import '../sources/local/driver_onboarding_draft_local_data_source.dart';

class DriverOnboardingDraftRepositoryImpl
    implements DriverOnboardingDraftRepository {
  DriverOnboardingDraftRepositoryImpl({
    required DriverOnboardingDraftLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final DriverOnboardingDraftLocalDataSource _localDataSource;

  @override
  Future<DriverOnboardingDraft?> readDraft() => _localDataSource.readDraft();

  @override
  Future<void> saveDraft(DriverOnboardingDraft draft) {
    return _localDataSource.saveDraft(draft);
  }

  @override
  Future<void> clearDraft() => _localDataSource.clearDraft();

  @override
  Future<DriverKycDocumentFile> persistDocument(
    DriverKycDocumentFile file, {
    required String namespace,
  }) {
    return _localDataSource.persistDocument(file, namespace: namespace);
  }

  @override
  Future<void> removePersistedDocument(String path) {
    return _localDataSource.removePersistedDocument(path);
  }

  @override
  Future<bool> documentExists(String path) {
    return _localDataSource.documentExists(path);
  }
}
