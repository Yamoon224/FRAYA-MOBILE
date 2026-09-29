library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_kyc_submission.dart';
import '../../../repositories/driver_kyc_repository.dart';
import '../../../usecases/usecase.dart';
import '../auth/driver_auth_failure_mapper.dart';

class SubmitDriverKycParams {
  const SubmitDriverKycParams({
    required this.userId,
    required this.submission,
  });

  final int userId;
  final DriverKycSubmission submission;
}

class SubmitDriverKycUseCase
    extends UseCase<Map<String, dynamic>, SubmitDriverKycParams> {
  SubmitDriverKycUseCase(this._repository);

  final DriverKycRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    SubmitDriverKycParams params,
  ) async {
    try {
      final response = await _repository.submitKyc(
        userId: params.userId,
        submission: params.submission,
      );
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
