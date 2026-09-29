library;

import '../../core/services/driver_document_preparation_service.dart';
import '../../domain/models/driver_kyc_document_file.dart';
import '../../domain/models/driver_kyc_document_type.dart';
import '../../domain/models/driver_vehicle_document_type.dart';
import '../../domain/models/driver_vehicle_submission.dart';
import '../../domain/models/driver_vehicle_update.dart';
import '../../domain/repositories/driver_vehicle_repository.dart';
import '../sources/remote/driver_vehicle_remote_data_source.dart';

class DriverVehicleRepositoryImpl implements DriverVehicleRepository {
  DriverVehicleRepositoryImpl({
    required DriverVehicleRemoteDataSource remoteDataSource,
    required DriverDocumentPreparationService preparationService,
  }) : _remoteDataSource = remoteDataSource,
       _preparationService = preparationService;

  final DriverVehicleRemoteDataSource _remoteDataSource;
  final DriverDocumentPreparationService _preparationService;

  @override
  Future<Map<String, dynamic>> submitVehicle({
    required DriverVehicleSubmission submission,
  }) async {
    final kycDocuments = await _prepareDocuments(submission.kycDocuments);
    Map<DriverVehicleDocumentType, DriverKycDocumentFile> vehicleDocuments;
    try {
      vehicleDocuments = await _prepareDocuments(submission.documents);
    } catch (_) {
      await _cleanupCreatedFiles(submission.kycDocuments, kycDocuments);
      rethrow;
    }
    try {
      return await _remoteDataSource.submitVehicle(
        submission: _copySubmission(submission, kycDocuments, vehicleDocuments),
      );
    } finally {
      await _cleanupCreatedFiles(submission.kycDocuments, kycDocuments);
      await _cleanupCreatedFiles(submission.documents, vehicleDocuments);
    }
  }

  @override
  Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required DriverVehicleUpdate update,
  }) {
    return _remoteDataSource.updateVehicle(
      vehicleId: vehicleId,
      update: update,
    );
  }

  DriverVehicleSubmission _copySubmission(
    DriverVehicleSubmission source,
    Map<DriverKycDocumentType, DriverKycDocumentFile> kycDocuments,
    Map<DriverVehicleDocumentType, DriverKycDocumentFile> vehicleDocuments,
  ) {
    return DriverVehicleSubmission(
      brand: source.brand,
      model: source.model,
      year: source.year,
      color: source.color,
      licensePlate: source.licensePlate,
      range: source.range,
      sidUserId: source.sidUserId,
      kycDocuments: kycDocuments,
      documents: vehicleDocuments,
      airConditioning: source.airConditioning,
    );
  }

  Future<Map<T, DriverKycDocumentFile>> _prepareDocuments<T>(
    Map<T, DriverKycDocumentFile> documents,
  ) async {
    final prepared = <T, DriverKycDocumentFile>{};
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

  Future<void> _cleanupCreatedFiles<T>(
    Map<T, DriverKycDocumentFile> source,
    Map<T, DriverKycDocumentFile> prepared,
  ) async {
    for (final entry in prepared.entries) {
      if (source[entry.key]?.path != entry.value.path) {
        await _preparationService.cleanupTemporary(entry.value);
      }
    }
  }
}
