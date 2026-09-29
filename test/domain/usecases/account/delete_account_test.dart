import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/error/failures.dart';
import 'package:fraya_mobile/domain/repositories/account_deletion_repository.dart';
import 'package:fraya_mobile/domain/usecases/account/delete_account.dart';

void main() {
  test('returns success when repository deletes account', () async {
    final repository = _AccountDeletionRepositoryFake();
    final useCase = DeleteAccountUseCase(repository);

    final result = await useCase(const DeleteAccountParams(userId: 15));

    expect(result.isRight(), isTrue);
    expect(repository.deletedUserId, 15);
  });

  test('maps server exception to failure', () async {
    final repository = _AccountDeletionRepositoryFake(
      error: const ServerException(message: 'Token JWT manquant ou invalide'),
    );
    final useCase = DeleteAccountUseCase(repository);

    final result = await useCase(const DeleteAccountParams(userId: 15));

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('Expected failure.'),
    );
  });
}

class _AccountDeletionRepositoryFake implements AccountDeletionRepository {
  _AccountDeletionRepositoryFake({this.error});

  final Object? error;
  int? deletedUserId;

  @override
  Future<void> deleteAccount(int userId) async {
    if (error != null) throw error!;
    deletedUserId = userId;
  }
}
