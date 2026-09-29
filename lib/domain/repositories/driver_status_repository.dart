library;

abstract class DriverStatusRepository {
  Future<void> updateStatus({required bool isOnline});

  Future<void> sendHeartbeat();
}
