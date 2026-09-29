import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/driver_status_repository_impl.dart';
import '../../../../data/sources/remote/driver_status_remote_data_source.dart';
import '../../../../domain/repositories/driver_status_repository.dart';
import '../../../../domain/usecases/driver/status/send_driver_heartbeat.dart';
import '../../../../domain/usecases/driver/status/update_driver_status.dart';

final driverStatusRemoteDataSourceProvider =
    Provider<DriverStatusRemoteDataSource>((ref) {
      return DriverStatusRemoteDataSource();
    });

final driverStatusRepositoryProvider = Provider<DriverStatusRepository>((ref) {
  final remoteDataSource = ref.watch(driverStatusRemoteDataSourceProvider);
  return DriverStatusRepositoryImpl(remoteDataSource: remoteDataSource);
});

final updateDriverStatusUseCaseProvider = Provider<UpdateDriverStatusUseCase>((
  ref,
) {
  final repository = ref.watch(driverStatusRepositoryProvider);
  return UpdateDriverStatusUseCase(repository);
});

final sendDriverHeartbeatUseCaseProvider = Provider<SendDriverHeartbeatUseCase>(
  (ref) {
    final repository = ref.watch(driverStatusRepositoryProvider);
    return SendDriverHeartbeatUseCase(repository);
  },
);
