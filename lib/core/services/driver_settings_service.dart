library;

import '../../data/sources/local_storage.dart';
import '../../data/sources/remote/driver_settings_remote_data_source.dart';
import '../utils/constants.dart';

class DriverSettingsService {
  DriverSettingsService({DriverSettingsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  DriverSettingsRemoteDataSource? _remoteDataSource;

  static const String _darkModeKey = AppConstants.themeKey;
  static const String _soundsEnabledKey = 'driver_sounds_enabled';
  static const String _notificationsEnabledKey = 'driver_notifications_enabled';

  Future<String> getLanguage() async {
    return LocalStorage.instance.getString(AppConstants.languageKey) ?? 'fr';
  }

  Future<void> setLanguage(String languageCode) async {
    await LocalStorage.instance.setString(
      AppConstants.languageKey,
      languageCode,
    );
  }

  Future<bool> isDarkModeEnabled() async {
    return LocalStorage.instance.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkModeEnabled(bool value) async {
    await LocalStorage.instance.setBool(_darkModeKey, value);
  }

  Future<bool> isSoundsEnabled() async {
    return LocalStorage.instance.getBool(_soundsEnabledKey) ?? true;
  }

  Future<void> setSoundsEnabled(bool value) async {
    await LocalStorage.instance.setBool(_soundsEnabledKey, value);
  }

  Future<bool> isNotificationsEnabled() async {
    return LocalStorage.instance.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await LocalStorage.instance.setBool(_notificationsEnabledKey, value);
  }

  Future<List<Map<String, dynamic>>> getOwnNotifications() {
    return _remote.getOwnNotifications();
  }

  Future<void> markNotificationsAsRead(List<int> ids) {
    return _remote.markNotificationsAsRead(notificationIds: ids);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _remote.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  DriverSettingsRemoteDataSource get _remote {
    return _remoteDataSource ??= DriverSettingsRemoteDataSource();
  }
}
