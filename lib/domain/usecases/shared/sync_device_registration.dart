library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../models/device_registration.dart';
import '../../repositories/device_registration_repository.dart';
import '../usecase.dart';
import 'device_registration_failure_mapper.dart';

class SyncDeviceRegistrationUseCase extends UseCase<void, DeviceRegistration> {
  SyncDeviceRegistrationUseCase(this._repository);

  final DeviceRegistrationRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeviceRegistration registration) async {
    try {
      final previous = await _repository.getLastRegistration();
      if (previous == registration) {
        return const Right(null);
      }
      if (previous != null) {
        try {
          await _repository.deactivate(previous);
        } catch (_) {
          // The new registration is more important than blocking login.
        }
      }
      await _repository.register(registration);
      await _repository.saveLastRegistration(registration);
      return const Right(null);
    } catch (error) {
      return left(mapDeviceRegistrationException(error));
    }
  }
}
