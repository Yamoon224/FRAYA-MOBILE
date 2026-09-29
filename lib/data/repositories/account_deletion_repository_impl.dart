library;

import '../../domain/repositories/account_deletion_repository.dart';
import '../sources/remote/account_deletion_remote_data_source.dart';

class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  AccountDeletionRepositoryImpl({
    required AccountDeletionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AccountDeletionRemoteDataSource _remoteDataSource;

  @override
  Future<void> deleteAccount(int userId) {
    return _remoteDataSource.deleteAccount(userId);
  }
}
