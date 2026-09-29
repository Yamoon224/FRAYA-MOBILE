library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/passenger_profile_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class ChangePassengerPhoneParams {
  const ChangePassengerPhoneParams({required this.otp});

  final String otp;
}

class ChangePassengerPhoneUseCase
    extends UseCase<void, ChangePassengerPhoneParams> {
  ChangePassengerPhoneUseCase(this._repository);

  final PassengerProfileRepository _repository;

  @override
  Future<Either<Failure, void>> call(ChangePassengerPhoneParams params) async {
    try {
      await _repository.confirmPhoneChange(params.otp);
      return const Right(null);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
