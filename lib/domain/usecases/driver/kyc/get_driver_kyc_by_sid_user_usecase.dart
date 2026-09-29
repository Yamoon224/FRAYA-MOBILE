library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_kyc_repository.dart';
import '../../../usecases/usecase.dart';
import '../auth/driver_auth_failure_mapper.dart';

class GetDriverKycBySidUserParams {
  const GetDriverKycBySidUserParams({required this.sidUserId});

  final int sidUserId;
}

class GetDriverKycBySidUserUseCase
    extends UseCase<Map<String, dynamic>, GetDriverKycBySidUserParams> {
  GetDriverKycBySidUserUseCase(this._repository);

  final DriverKycRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    GetDriverKycBySidUserParams params,
  ) async {
    try {
      final response = await _repository.getKycBySidUser(
        sidUserId: params.sidUserId,
      );
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
