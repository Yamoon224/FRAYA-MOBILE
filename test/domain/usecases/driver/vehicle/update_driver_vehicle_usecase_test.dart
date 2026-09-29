import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/error/failures.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_submission.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_update.dart';
import 'package:fraya_mobile/domain/repositories/driver_vehicle_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/vehicle/update_driver_vehicle_usecase.dart';

class RecordingDriverVehicleRepository implements DriverVehicleRepository {
  int? lastVehicleId;
  DriverVehicleUpdate? lastUpdate;
  Map<String, dynamic> response = const {'id': 7};
  Object? error;

  @override
  Future<Map<String, dynamic>> submitVehicle({
    required DriverVehicleSubmission submission,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required DriverVehicleUpdate update,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastVehicleId = vehicleId;
    lastUpdate = update;
    return response;
  }
}

void main() {
  group('UpdateDriverVehicleUseCase', () {
    test('forwards vehicle update to repository', () async {
      final repository = RecordingDriverVehicleRepository();
      final useCase = UpdateDriverVehicleUseCase(repository);
      const update = DriverVehicleUpdate(
        brand: 'Toyota',
        model: 'Corolla',
        year: '2022',
        color: 'Noir',
        licensePlate: 'AA-000-AA',
        range: 'MAGIC',
        airConditioning: true,
      );

      final result = await useCase(
        const UpdateDriverVehicleParams(vehicleId: 7, update: update),
      );

      expect(result.isRight(), isTrue);
      expect(repository.lastVehicleId, 7);
      expect(repository.lastUpdate, same(update));
    });

    test('maps validation exceptions to validation failures', () async {
      final repository = RecordingDriverVehicleRepository()
        ..error = const ValidationException(message: 'Plaque invalide.');
      final useCase = UpdateDriverVehicleUseCase(repository);

      final result = await useCase(
        const UpdateDriverVehicleParams(
          vehicleId: 7,
          update: DriverVehicleUpdate(
            brand: 'Toyota',
            model: 'Corolla',
            year: '2022',
            color: 'Noir',
            licensePlate: 'AA-000-AA',
            range: 'MAGIC',
            airConditioning: false,
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
