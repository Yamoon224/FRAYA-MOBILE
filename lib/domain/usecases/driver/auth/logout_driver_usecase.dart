library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/constants.dart';
import '../../../../data/sources/local_storage.dart';
import '../../shared/deactivate_device_registration.dart';
import '../../../usecases/usecase.dart';

class LogoutDriverUseCase extends UseCaseNoParams<void> {
  LogoutDriverUseCase({
    DeactivateDeviceRegistrationUseCase? deactivateDeviceRegistrationUseCase,
  }) : _deactivateDeviceRegistrationUseCase =
           deactivateDeviceRegistrationUseCase;

  final DeactivateDeviceRegistrationUseCase?
  _deactivateDeviceRegistrationUseCase;

  @override
  Future<Either<Failure, void>> call() async {
    final deactivateDeviceRegistrationUseCase =
        _deactivateDeviceRegistrationUseCase;
    if (deactivateDeviceRegistrationUseCase != null) {
      final result = await deactivateDeviceRegistrationUseCase
          .callLastRegistration();
      result.fold(
        (failure) => logger.warning(
          'Desactivation device chauffeur ignoree: ${failure.message}',
        ),
        (_) {},
      );
    }
    await LocalStorage.instance.deleteSecure(
      AppConstants.driverAuthUserDataKey,
    );
    await LocalStorage.instance.deleteSecure(AppConstants.driverAccessTokenKey);
    await LocalStorage.instance.deleteSecure(AppConstants.refreshTokenKey);
    return right(null);
  }
}
