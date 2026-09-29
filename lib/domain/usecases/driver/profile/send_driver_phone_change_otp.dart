library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_profile_repository.dart';
import '../../passenger/auth_failure_mapper.dart';
import '../../usecase.dart';

class SendDriverPhoneChangeOtpUseCase extends UseCase<void, String> {
  SendDriverPhoneChangeOtpUseCase(this._repository);

  final DriverProfileRepository _repository;

  @override
  Future<Either<Failure, void>> call(String phoneNumber) async {
    try {
      await _repository.requestPhoneChange(phoneNumber);
      return const Right(null);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
