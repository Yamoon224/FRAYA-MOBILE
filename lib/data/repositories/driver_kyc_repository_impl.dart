library;

import '../../core/services/driver_document_preparation_service.dart';
import '../../domain/models/driver_kyc_document_file.dart';
import '../../domain/models/driver_kyc_document_type.dart';
import '../../domain/models/driver_kyc_submission.dart';
import '../../domain/repositories/driver_kyc_repository.dart';
import '../sources/remote/driver_kyc_remote_data_source.dart';

class DriverKycRepositoryImpl implements DriverKycRepository {
  DriverKycRepositoryImpl({
    required DriverKycRemoteDataSource remoteDataSource,
    required DriverDocumentPreparationService preparationService,
  }) : _remoteDataSource = remoteDataSource,
       _preparationService = preparationService;

  final DriverKycRemoteDataSource _remoteDataSource;
  final DriverDocumentPreparationService _preparationService;

  @override
  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required DriverKycSubmission submission,
  }) async {
    final prepared = await _prepareDocuments(submission.documents);
    try {
      return await _remoteDataSource.submitKyc(
        userId: userId,
        submission: DriverKycSubmission(documents: prepared),
      );
    } finally {
      await _cleanupCreatedFiles(submission.documents, prepared);
    }
  }

  @override
  Future<Map<String, dynamic>> updateKyc({
    required int kycId,
    required Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  }) async {
    final prepared = await _prepareDocuments(documents);
    try {
      return await _remoteDataSource.updateKyc(
        kycId: kycId,
        documents: prepared,
      );
    } finally {
      await _cleanupCreatedFiles(documents, prepared);
    }
  }

  @override
  Future<Map<String, dynamic>> getKycBySidUser({required int sidUserId}) {
    return _remoteDataSource.getKycBySidUser(sidUserId: sidUserId);
  }

  Future<Map<DriverKycDocumentType, DriverKycDocumentFile>> _prepareDocuments(
    Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  ) async {
    final prepared = <DriverKycDocumentType, DriverKycDocumentFile>{};
    try {
      for (final entry in documents.entries) {
        prepared[entry.key] = await _preparationService.prepare(entry.value);
      }
      return prepared;
    } catch (_) {
      await _cleanupCreatedFiles(documents, prepared);
      rethrow;
    }
  }

  Future<void> _cleanupCreatedFiles(
    Map<DriverKycDocumentType, DriverKycDocumentFile> source,
    Map<DriverKycDocumentType, DriverKycDocumentFile> prepared,
  ) async {
    for (final entry in prepared.entries) {
      if (source[entry.key]?.path != entry.value.path) {
        await _preparationService.cleanupTemporary(entry.value);
      }
    }
  }
}
