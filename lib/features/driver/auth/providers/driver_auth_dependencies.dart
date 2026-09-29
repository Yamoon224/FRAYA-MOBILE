library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/driver_auth_repository_impl.dart';
import '../../../../data/sources/remote/driver_auth_remote_data_source.dart';
import '../../../../domain/repositories/driver_auth_repository.dart';
import '../../../../domain/usecases/driver/auth/login_driver_usecase.dart';
import '../../../../domain/usecases/driver/auth/logout_driver_usecase.dart';
import '../../../../domain/usecases/driver/auth/refresh_driver_profile_usecase.dart';
import '../../../../domain/usecases/driver/auth/register_driver_usecase.dart';
import '../../../../domain/usecases/driver/auth/register_driver_step1_usecase.dart';
import '../../../../domain/usecases/driver/auth/register_driver_step2_usecase.dart';
import '../../../../shared/providers/device_registration_provider.dart';

final driverAuthRemoteDataSourceProvider = Provider<DriverAuthRemoteDataSource>(
  (ref) {
    return DriverAuthRemoteDataSource();
  },
);

final driverAuthRepositoryProvider = Provider<DriverAuthRepository>((ref) {
  final remoteDataSource = ref.watch(driverAuthRemoteDataSourceProvider);
  return DriverAuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

final loginDriverUseCaseProvider = Provider<LoginDriverUseCase>((ref) {
  final repository = ref.watch(driverAuthRepositoryProvider);
  return LoginDriverUseCase(repository);
});

final registerDriverUseCaseProvider = Provider<RegisterDriverUseCase>((ref) {
  final repository = ref.watch(driverAuthRepositoryProvider);
  return RegisterDriverUseCase(repository);
});

final registerDriverStep1UseCaseProvider = Provider<RegisterDriverStep1UseCase>(
  (ref) {
    final repository = ref.watch(driverAuthRepositoryProvider);
    return RegisterDriverStep1UseCase(repository);
  },
);

final registerDriverStep2UseCaseProvider = Provider<RegisterDriverStep2UseCase>(
  (ref) {
    final repository = ref.watch(driverAuthRepositoryProvider);
    return RegisterDriverStep2UseCase(repository);
  },
);

final refreshDriverProfileUseCaseProvider =
    Provider<RefreshDriverProfileUseCase>((ref) {
      final repository = ref.watch(driverAuthRepositoryProvider);
      return RefreshDriverProfileUseCase(repository);
    });

final logoutDriverUseCaseProvider = Provider<LogoutDriverUseCase>((ref) {
  return LogoutDriverUseCase(
    deactivateDeviceRegistrationUseCase: ref.watch(
      deactivateDeviceRegistrationUseCaseProvider,
    ),
  );
});
