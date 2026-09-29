import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/repositories/driver_vehicle_repository_impl.dart';
import 'package:fraya_mobile/data/sources/remote/driver_vehicle_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_submission.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_update.dart';

import '../../support/driver_document_preparation_test_double.dart';

class FakeDriverVehicleRemoteDataSource extends DriverVehicleRemoteDataSource {
  FakeDriverVehicleRemoteDataSource() : super(dio: Dio());

  DriverVehicleSubmission? lastSubmission;
  DriverVehicleUpdate? lastUpdate;
  int? lastUpdateVehicleId;

  @override
  Future<Map<String, dynamic>> submitVehicle({
    required DriverVehicleSubmission submission,
  }) async {
    lastSubmission = submission;
    return {'id': 12};
  }

  @override
  Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required DriverVehicleUpdate update,
  }) async {
    lastUpdateVehicleId = vehicleId;
    lastUpdate = update;
    return {'id': vehicleId, 'vehicleStatus': 'PENDING_VALIDATION'};
  }
}

void main() {
  group('DriverVehicleRepositoryImpl', () {
    test('delegates submission to remote data source', () async {
      final remoteDataSource = FakeDriverVehicleRemoteDataSource();
      final repository = DriverVehicleRepositoryImpl(
        remoteDataSource: remoteDataSource,
        preparationService: PassthroughDriverDocumentPreparationService(),
      );
      final submission = DriverVehicleSubmission(
        brand: 'Toyota',
        model: 'Corolla',
        year: '2022',
        color: 'Blanc',
        licensePlate: 'AB-123-CD',
        range: 'MAGIC',
        sidUserId: 9,
        kycDocuments: const {},
        documents: {
          DriverVehicleDocumentType.vehicleRegistration:
              DriverKycDocumentFile.fromPath(
                path: '/tmp/carte_grise.pdf',
                fileName: 'carte_grise.pdf',
                source: DriverKycDocumentSource.pdfFile,
              )!,
        },
      );

      final response = await repository.submitVehicle(submission: submission);

      expect(response['id'], 12);
      expect(remoteDataSource.lastSubmission?.brand, submission.brand);
      expect(remoteDataSource.lastSubmission?.documents, submission.documents);
    });

    test('delegates vehicle update to remote data source', () async {
      final remoteDataSource = FakeDriverVehicleRemoteDataSource();
      final repository = DriverVehicleRepositoryImpl(
        remoteDataSource: remoteDataSource,
        preparationService: PassthroughDriverDocumentPreparationService(),
      );
      const update = DriverVehicleUpdate(
        brand: 'Toyota',
        model: 'Corolla',
        year: '2022',
        color: 'Blanc',
        licensePlate: 'AB-123-CD',
        range: 'MAGIC',
        airConditioning: true,
      );

      final response = await repository.updateVehicle(
        vehicleId: 7,
        update: update,
      );

      expect(response['id'], 7);
      expect(remoteDataSource.lastUpdateVehicleId, 7);
      expect(remoteDataSource.lastUpdate, same(update));
    });
  });
}
