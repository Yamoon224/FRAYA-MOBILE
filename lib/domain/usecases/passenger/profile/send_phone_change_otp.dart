library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/passenger_profile_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class SendPhoneChangeOtpUseCase extends UseCase<void, String> {
  SendPhoneChangeOtpUseCase(this._repository);

  final PassengerProfileRepository _repository;

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
