library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/utils/constants.dart';
import '../../../domain/models/driver_kyc_document_file.dart';
import '../../../domain/models/driver_onboarding_draft.dart';
import '../../sources/local_storage.dart';

class DriverOnboardingDraftLocalDataSource {
  DriverOnboardingDraftLocalDataSource({
    LocalStorage? localStorage,
    Future<Directory> Function()? resolveBaseDirectory,
  }) : _localStorage = localStorage ?? LocalStorage.instance,
       _resolveBaseDirectory =
           resolveBaseDirectory ?? getApplicationDocumentsDirectory;

  final LocalStorage _localStorage;
  final Future<Directory> Function() _resolveBaseDirectory;

  Future<DriverOnboardingDraft?> readDraft() async {
    final raw = _localStorage.getString(AppConstants.driverOnboardingDraftKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return DriverOnboardingDraft.fromMap(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> saveDraft(DriverOnboardingDraft draft) async {
    await _localStorage.setString(
      AppConstants.driverOnboardingDraftKey,
      jsonEncode(draft.toMap()),
    );
  }

  Future<void> clearDraft() async {
    final draft = await readDraft();
    if (draft != null) {
      await _deleteDraftFiles(draft);
    }
    await _deleteDraftDirectory();
    await _localStorage.remove(AppConstants.driverOnboardingDraftKey);
  }

  Future<DriverKycDocumentFile> persistDocument(
    DriverKycDocumentFile file, {
    required String namespace,
  }) async {
    final sourceFile = File(file.path);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Document introuvable', file.path);
    }

    final extension = _resolveExtension(file.fileName, file.path);
    final draftDirectory = await _resolveDraftDirectory();
    final targetPath =
        '${draftDirectory.path}${Platform.pathSeparator}${_sanitize(namespace)}$extension';
    if (_normalizePath(file.path) == _normalizePath(targetPath)) {
      return file;
    }

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await sourceFile.copy(targetPath);
    return DriverKycDocumentFile(
      path: targetPath,
      fileName: file.fileName,
      mimeType: file.mimeType,
      source: file.source,
    );
  }

  Future<void> removePersistedDocument(String path) async {
    if (path.trim().isEmpty) {
      return;
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> documentExists(String path) async {
    if (path.trim().isEmpty) {
      return false;
    }
    return File(path).exists();
  }

  Future<Directory> _resolveDraftDirectory() async {
    final baseDirectory = await _resolveBaseDirectory();
    final directory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}${AppConstants.driverOnboardingDraftDirectory}',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<void> _deleteDraftFiles(DriverOnboardingDraft draft) async {
    final paths = <String>{
      ...draft.kycDocuments.values.map((document) => document.path),
      ...draft.vehicleDocuments.values.map((document) => document.path),
    };
    for (final path in paths) {
      await removePersistedDocument(path);
    }
  }

  Future<void> _deleteDraftDirectory() async {
    final baseDirectory = await _resolveBaseDirectory();
    final directory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}${AppConstants.driverOnboardingDraftDirectory}',
    );
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

String _resolveExtension(String fileName, String path) {
  final source = fileName.trim().isEmpty ? path : fileName;
  final dotIndex = source.lastIndexOf('.');
  if (dotIndex <= -1 || dotIndex == source.length - 1) {
    return '';
  }
  return source.substring(dotIndex);
}

String _sanitize(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

String _normalizePath(String path) {
  return path.replaceAll('\\', '/').trim().toLowerCase();
}
