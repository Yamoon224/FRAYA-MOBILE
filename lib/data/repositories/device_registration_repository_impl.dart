library;

import 'dart:convert';

import '../../core/utils/constants.dart';
import '../../domain/models/device_registration.dart';
import '../../domain/repositories/device_registration_repository.dart';
import '../sources/local_storage.dart';
import '../sources/remote/device_registration_remote_data_source.dart';

class DeviceRegistrationRepositoryImpl implements DeviceRegistrationRepository {
  DeviceRegistrationRepositoryImpl({
    required DeviceRegistrationRemoteDataSource remoteDataSource,
    LocalStorage? localStorage,
  }) : _remoteDataSource = remoteDataSource,
       _localStorage = localStorage ?? LocalStorage.instance;

  final DeviceRegistrationRemoteDataSource _remoteDataSource;
  final LocalStorage _localStorage;

  @override
  Future<void> register(DeviceRegistration registration) {
    return _remoteDataSource.register(registration);
  }

  @override
  Future<void> deactivate(DeviceRegistration registration) {
    return _remoteDataSource.deactivate(registration);
  }

  @override
  Future<DeviceRegistration?> getLastRegistration() async {
    final raw = _localStorage.getString(
      AppConstants.activeDeviceRegistrationKey,
    );
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await clearLastRegistration();
        return null;
      }
      return DeviceRegistration.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await clearLastRegistration();
      return null;
    }
  }

  @override
  Future<void> saveLastRegistration(DeviceRegistration registration) async {
    await _localStorage.setString(
      AppConstants.activeDeviceRegistrationKey,
      jsonEncode(registration.toJson()),
    );
  }

  @override
  Future<void> clearLastRegistration() async {
    await _localStorage.remove(AppConstants.activeDeviceRegistrationKey);
  }
}
