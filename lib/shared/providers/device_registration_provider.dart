library;

import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/device_registration_repository_impl.dart';
import '../../data/sources/remote/device_registration_remote_data_source.dart';
import '../../domain/repositories/device_registration_repository.dart';
import '../../domain/usecases/shared/deactivate_device_registration.dart';
import '../../domain/usecases/shared/sync_device_registration.dart';

typedef DeviceRegistrationPlatformResolver = String? Function();

final deviceRegistrationRemoteDataSourceProvider =
    Provider<DeviceRegistrationRemoteDataSource>((ref) {
      return DeviceRegistrationRemoteDataSource();
    });

final deviceRegistrationRepositoryProvider =
    Provider<DeviceRegistrationRepository>((ref) {
      return DeviceRegistrationRepositoryImpl(
        remoteDataSource: ref.watch(deviceRegistrationRemoteDataSourceProvider),
      );
    });

final syncDeviceRegistrationUseCaseProvider =
    Provider<SyncDeviceRegistrationUseCase>((ref) {
      return SyncDeviceRegistrationUseCase(
        ref.watch(deviceRegistrationRepositoryProvider),
      );
    });

final deactivateDeviceRegistrationUseCaseProvider =
    Provider<DeactivateDeviceRegistrationUseCase>((ref) {
      return DeactivateDeviceRegistrationUseCase(
        ref.watch(deviceRegistrationRepositoryProvider),
      );
    });

final deviceRegistrationPlatformProvider =
    Provider<DeviceRegistrationPlatformResolver>((ref) {
      return defaultDeviceRegistrationPlatform;
    });

String? defaultDeviceRegistrationPlatform() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return null;
}
