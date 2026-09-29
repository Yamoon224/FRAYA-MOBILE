library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/account_deletion_repository_impl.dart';
import '../../data/sources/remote/account_deletion_remote_data_source.dart';
import '../../domain/repositories/account_deletion_repository.dart';
import '../../domain/usecases/account/delete_account.dart';

final accountDeletionRemoteDataSourceProvider =
    Provider<AccountDeletionRemoteDataSource>((ref) {
      return AccountDeletionRemoteDataSource();
    });

final accountDeletionRepositoryProvider = Provider<AccountDeletionRepository>((
  ref,
) {
  final remoteDataSource = ref.watch(accountDeletionRemoteDataSourceProvider);
  return AccountDeletionRepositoryImpl(remoteDataSource: remoteDataSource);
});

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  final repository = ref.watch(accountDeletionRepositoryProvider);
  return DeleteAccountUseCase(repository);
});
