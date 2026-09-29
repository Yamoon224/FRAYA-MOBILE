library;

import '../../domain/repositories/driver_status_repository.dart';
import '../sources/remote/driver_status_remote_data_source.dart';

class DriverStatusRepositoryImpl implements DriverStatusRepository {
  DriverStatusRepositoryImpl({
    required DriverStatusRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DriverStatusRemoteDataSource _remoteDataSource;

  @override
  Future<void> updateStatus({required bool isOnline}) {
    return _remoteDataSource.updateStatus(isOnline: isOnline);
  }

  @override
  Future<void> sendHeartbeat() => _remoteDataSource.sendHeartbeat();
}
