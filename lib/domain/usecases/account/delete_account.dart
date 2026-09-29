library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failure_mapper.dart';
import '../../../core/error/failures.dart';
import '../../repositories/account_deletion_repository.dart';
import '../usecase.dart';

class DeleteAccountParams {
  const DeleteAccountParams({required this.userId});

  final int userId;
}

class DeleteAccountUseCase extends UseCase<void, DeleteAccountParams> {
  DeleteAccountUseCase(this._repository);

  final AccountDeletionRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) async {
    try {
      await _repository.deleteAccount(params.userId);
      return right(null);
    } catch (error) {
      return left(mapAppException(error));
    }
  }
}
