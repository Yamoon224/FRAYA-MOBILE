library;

abstract class AccountDeletionRepository {
  Future<void> deleteAccount(int userId);
}
