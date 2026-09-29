library;

import '../models/device_registration.dart';

abstract class DeviceRegistrationRepository {
  Future<void> register(DeviceRegistration registration);

  Future<void> deactivate(DeviceRegistration registration);

  Future<DeviceRegistration?> getLastRegistration();

  Future<void> saveLastRegistration(DeviceRegistration registration);

  Future<void> clearLastRegistration();
}
