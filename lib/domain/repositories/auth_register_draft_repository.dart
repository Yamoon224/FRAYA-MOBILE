library;

import '../models/auth_register_draft.dart';

abstract class AuthRegisterDraftRepository {
  Future<AuthRegisterDraft?> readDraft(AuthRegisterRole role);

  Future<void> saveDraft(AuthRegisterDraft draft);

  Future<void> clearDraft(AuthRegisterRole role);
}
