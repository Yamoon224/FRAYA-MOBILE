library;

import '../../domain/models/auth_register_draft.dart';
import '../../domain/repositories/auth_register_draft_repository.dart';
import '../sources/local/auth_register_draft_local_data_source.dart';

class AuthRegisterDraftRepositoryImpl implements AuthRegisterDraftRepository {
  AuthRegisterDraftRepositoryImpl({
    required AuthRegisterDraftLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final AuthRegisterDraftLocalDataSource _localDataSource;

  @override
  Future<AuthRegisterDraft?> readDraft(AuthRegisterRole role) {
    return _localDataSource.readDraft(role);
  }

  @override
  Future<void> saveDraft(AuthRegisterDraft draft) {
    return _localDataSource.saveDraft(draft);
  }

  @override
  Future<void> clearDraft(AuthRegisterRole role) {
    return _localDataSource.clearDraft(role);
  }
}
