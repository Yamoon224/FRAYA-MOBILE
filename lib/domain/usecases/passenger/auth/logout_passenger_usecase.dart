library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/sources/local_storage.dart';
import '../../../../core/utils/constants.dart';
import '../../shared/deactivate_device_registration.dart';
import '../../usecase.dart';

class LogoutPassengerUsecase extends UseCaseNoParams<void> {
  LogoutPassengerUsecase({
    DeactivateDeviceRegistrationUseCase? deactivateDeviceRegistrationUseCase,
  }) : _deactivateDeviceRegistrationUseCase =
           deactivateDeviceRegistrationUseCase;

  static const String _userKey = AppConstants.authUserDataKey;
  static const String _tokenKey = AppConstants.accessTokenKey;
  static const String _refreshTokenKey = AppConstants.refreshTokenKey;

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
          'Desactivation device passager ignoree: ${failure.message}',
        ),
        (_) {},
      );
    }
    await LocalStorage.instance.deleteSecure(_userKey);
    await LocalStorage.instance.deleteSecure(_tokenKey);
    await LocalStorage.instance.deleteSecure(_refreshTokenKey);
    return right(null);
  }
}
