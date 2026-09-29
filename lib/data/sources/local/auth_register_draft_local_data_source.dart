library;

import 'dart:convert';

import '../../../core/utils/constants.dart';
import '../../../domain/models/auth_register_draft.dart';
import '../../sources/local_storage.dart';

class AuthRegisterDraftLocalDataSource {
  AuthRegisterDraftLocalDataSource({LocalStorage? localStorage})
    : _localStorage = localStorage ?? LocalStorage.instance;

  final LocalStorage _localStorage;
  static const int _schemaVersion = 1;

  Future<AuthRegisterDraft?> readDraft(AuthRegisterRole role) async {
    final raw = _localStorage.getString(_keyForRole(role));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['schemaVersion'] != _schemaVersion) {
        await clearDraft(role);
        return null;
      }
      final draft = AuthRegisterDraft.fromMap(
        Map<String, dynamic>.from(decoded),
      );
      return draft.role == role ? draft : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveDraft(AuthRegisterDraft draft) async {
    await _localStorage.setString(
      _keyForRole(draft.role),
      jsonEncode({...draft.toMap(), 'schemaVersion': _schemaVersion}),
    );
  }

  Future<void> clearDraft(AuthRegisterRole role) async {
    await _localStorage.remove(_keyForRole(role));
  }
}

String _keyForRole(AuthRegisterRole role) {
  return switch (role) {
    AuthRegisterRole.passenger => AppConstants.passengerRegisterDraftKey,
    AuthRegisterRole.driver => AppConstants.driverRegisterDraftKey,
  };
}
