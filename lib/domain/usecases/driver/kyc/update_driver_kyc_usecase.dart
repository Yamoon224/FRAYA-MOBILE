library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_kyc_document_file.dart';
import '../../../models/driver_kyc_document_type.dart';
import '../../../repositories/driver_kyc_repository.dart';
import '../../../usecases/usecase.dart';
import '../auth/driver_auth_failure_mapper.dart';

class UpdateDriverKycParams {
  const UpdateDriverKycParams({
    required this.kycId,
    required this.documents,
  });

  final int kycId;
  final Map<DriverKycDocumentType, DriverKycDocumentFile> documents;
}

class UpdateDriverKycUseCase
    extends UseCase<Map<String, dynamic>, UpdateDriverKycParams> {
  UpdateDriverKycUseCase(this._repository);

  final DriverKycRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    UpdateDriverKycParams params,
  ) async {
    try {
      final response = await _repository.updateKyc(
        kycId: params.kycId,
        documents: params.documents,
      );
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
