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
  int? lastSecondaryVehicleId;
  String? lastSecondaryRange;
  Map<DriverVehicleDocumentType, DriverKycDocumentFile>? lastRequestPhotos;

  @override
  Future<Map<String, dynamic>> submitVehicle({
    required DriverVehicleSubmission submission,
  }) async {
    lastSubmission = submission;
    return {'id': 12};
  }

  @override
  Future<Map<String, dynamic>> updateSecondaryRange({
    required int vehicleId,
    required String? secondaryRange,
  }) async {
    lastSecondaryVehicleId = vehicleId;
    lastSecondaryRange = secondaryRange;
    return {'id': vehicleId, 'secondaryRange': secondaryRange};
  }

  @override
  Future<Map<String, dynamic>> requestSecondaryRange({
    required int vehicleId,
    required String secondaryRange,
    required Map<DriverVehicleDocumentType, DriverKycDocumentFile> photos,
  }) async {
    lastSecondaryVehicleId = vehicleId;
    lastSecondaryRange = secondaryRange;
    lastRequestPhotos = photos;
    return {'id': 1};
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

    test('conserve la seconde gamme choisie lors de la soumission', () async {
      final remoteDataSource = FakeDriverVehicleRemoteDataSource();
      final repository = DriverVehicleRepositoryImpl(
        remoteDataSource: remoteDataSource,
        preparationService: PassthroughDriverDocumentPreparationService(),
      );

      await repository.submitVehicle(
        submission: DriverVehicleSubmission(
          brand: 'Toyota',
          model: 'Corolla',
          year: '2022',
          color: 'Blanc',
          licensePlate: 'AB-123-CD',
          range: 'MAGIC',
          secondaryRange: 'GLADIATEUR',
          sidUserId: 9,
          kycDocuments: const {},
          documents: const {},
        ),
      );

      expect(remoteDataSource.lastSubmission?.range, 'MAGIC');
      expect(remoteDataSource.lastSubmission?.secondaryRange, 'GLADIATEUR');
    });

    test('retire ou remplace la seconde gamme via la source distante', () async {
      final remoteDataSource = FakeDriverVehicleRemoteDataSource();
      final repository = DriverVehicleRepositoryImpl(
        remoteDataSource: remoteDataSource,
        preparationService: PassthroughDriverDocumentPreparationService(),
      );

      await repository.updateSecondaryRange(vehicleId: 7, secondaryRange: null);
      expect(remoteDataSource.lastSecondaryVehicleId, 7);
      expect(remoteDataSource.lastSecondaryRange, isNull);

      await repository.updateSecondaryRange(vehicleId: 7, secondaryRange: 'MAGIC');
      expect(remoteDataSource.lastSecondaryRange, 'MAGIC');
    });

    test('envoie la demande de seconde gamme avec les photos préparées', () async {
      final remoteDataSource = FakeDriverVehicleRemoteDataSource();
      final repository = DriverVehicleRepositoryImpl(
        remoteDataSource: remoteDataSource,
        preparationService: PassthroughDriverDocumentPreparationService(),
      );
      final photos = {
        DriverVehicleDocumentType.photoFrontVehicle:
            DriverKycDocumentFile.fromPath(
              path: '/tmp/front.jpg',
              fileName: 'front.jpg',
              source: DriverKycDocumentSource.galleryImage,
            )!,
      };

      await repository.requestSecondaryRange(
        vehicleId: 7,
        secondaryRange: 'ELITE',
        photos: photos,
      );

      expect(remoteDataSource.lastSecondaryRange, 'ELITE');
      expect(remoteDataSource.lastRequestPhotos?.keys, photos.keys);
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
