import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/error/failures.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_submission.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_update.dart';
import 'package:fraya_mobile/domain/repositories/driver_vehicle_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/vehicle/submit_driver_vehicle_usecase.dart';

class RecordingDriverVehicleRepository implements DriverVehicleRepository {
  DriverVehicleSubmission? lastSubmission;
  Map<String, dynamic> response = const {'id': 1};
  Object? error;

  @override
  Future<Map<String, dynamic>> submitVehicle({
    required DriverVehicleSubmission submission,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastSubmission = submission;
    return response;
  }

  @override
  Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required DriverVehicleUpdate update,
  }) async {
    if (error != null) {
      throw error!;
    }
    return response;
  }
}

void main() {
  group('SubmitDriverVehicleUseCase', () {
    test('forwards submission to repository', () async {
      final repository = RecordingDriverVehicleRepository();
      final useCase = SubmitDriverVehicleUseCase(repository);
      final submission = DriverVehicleSubmission(
        brand: 'Toyota',
        model: 'Corolla',
        year: '2021',
        color: 'Noir',
        licensePlate: 'AA-000-AA',
        range: 'ELITE',
        sidUserId: 12,
        kycDocuments: {
          DriverKycDocumentType.photoFrontPermis:
              DriverKycDocumentFile.fromPath(
                path: '/tmp/permis.png',
                fileName: 'permis.png',
                source: DriverKycDocumentSource.galleryImage,
              )!,
        },
        documents: {
          DriverVehicleDocumentType.photoFrontVehicle:
              DriverKycDocumentFile.fromPath(
                path: '/tmp/vehicle.png',
                fileName: 'vehicle.png',
                source: DriverKycDocumentSource.galleryImage,
              )!,
        },
      );

      final result = await useCase(
        SubmitDriverVehicleParams(submission: submission),
      );

      expect(result.isRight(), isTrue);
      expect(repository.lastSubmission, same(submission));
    });

    test('maps validation exceptions to validation failures', () async {
      final repository = RecordingDriverVehicleRepository()
        ..error = const ValidationException(message: 'Plaque invalide.');
      final useCase = SubmitDriverVehicleUseCase(repository);

      final result = await useCase(
        SubmitDriverVehicleParams(
          submission: DriverVehicleSubmission(
            brand: 'Toyota',
            model: 'Corolla',
            year: '2021',
            color: 'Noir',
            licensePlate: 'AA-000-AA',
            range: 'MAGIC',
            sidUserId: 12,
            kycDocuments: const {},
            documents: const {},
          ),
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Plaque invalide.');
      }, (_) => fail('Expected a validation failure'));
    });
  });
}
