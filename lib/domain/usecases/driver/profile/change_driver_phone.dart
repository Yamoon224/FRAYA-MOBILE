library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_profile_repository.dart';
import '../../passenger/auth_failure_mapper.dart';
import '../../usecase.dart';

class ChangeDriverPhoneParams {
  const ChangeDriverPhoneParams({required this.otp});

  final String otp;
}

class ChangeDriverPhoneUseCase extends UseCase<void, ChangeDriverPhoneParams> {
  ChangeDriverPhoneUseCase(this._repository);

  final DriverProfileRepository _repository;

  @override
  Future<Either<Failure, void>> call(ChangeDriverPhoneParams params) async {
    try {
      await _repository.confirmPhoneChange(params.otp);
      return const Right(null);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
