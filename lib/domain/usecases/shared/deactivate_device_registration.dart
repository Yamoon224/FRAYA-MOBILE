library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../models/device_registration.dart';
import '../../repositories/device_registration_repository.dart';
import '../usecase.dart';
import 'device_registration_failure_mapper.dart';

class DeactivateDeviceRegistrationParams {
  const DeactivateDeviceRegistrationParams({this.registration});

  final DeviceRegistration? registration;
}

class DeactivateDeviceRegistrationUseCase
    extends UseCase<void, DeactivateDeviceRegistrationParams> {
  DeactivateDeviceRegistrationUseCase(this._repository);

  final DeviceRegistrationRepository _repository;

  Future<Either<Failure, void>> callLastRegistration() {
    return call(const DeactivateDeviceRegistrationParams());
  }

  @override
  Future<Either<Failure, void>> call(
    DeactivateDeviceRegistrationParams params,
  ) async {
    try {
      final registration =
          params.registration ?? await _repository.getLastRegistration();
      if (registration == null) {
        return const Right(null);
      }
      await _repository.deactivate(registration);
      await _repository.clearLastRegistration();
      return const Right(null);
    } catch (error) {
      return left(mapDeviceRegistrationException(error));
    }
  }
}
