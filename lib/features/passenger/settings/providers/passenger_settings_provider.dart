import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/services/passenger_settings_service.dart';

class PassengerSettingsState {
  const PassengerSettingsState({
    this.languageCode = 'fr',
    this.darkModeEnabled = false,
    this.soundsEnabled = true,
    this.notificationsEnabled = true,
    this.isLoading = false,
  });

  final String languageCode;
  final bool darkModeEnabled;
  final bool soundsEnabled;
  final bool notificationsEnabled;
  final bool isLoading;

  PassengerSettingsState copyWith({
    String? languageCode,
    bool? darkModeEnabled,
    bool? soundsEnabled,
    bool? notificationsEnabled,
    bool? isLoading,
  }) {
    return PassengerSettingsState(
      languageCode: languageCode ?? this.languageCode,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PassengerSettingsNotifier extends StateNotifier<PassengerSettingsState> {
  PassengerSettingsNotifier(this._service)
    : super(const PassengerSettingsState()) {
    load();
  }

  final PassengerSettingsService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final language = await _service.getLanguage();
    final darkMode = await _service.isDarkModeEnabled();
    final sounds = await _service.isSoundsEnabled();
    final notifications = await _service.isNotificationsEnabled();
    state = state.copyWith(
      languageCode: language,
      darkModeEnabled: darkMode,
      soundsEnabled: sounds,
      notificationsEnabled: notifications,
      isLoading: false,
    );
  }

  Future<void> setLanguage(String code) async {
    await _service.setLanguage(code);
    state = state.copyWith(languageCode: code);
  }

  Future<void> toggleDarkMode() async {
    final next = !state.darkModeEnabled;
    state = state.copyWith(darkModeEnabled: next);
    await _service.setDarkModeEnabled(next);
  }

  Future<void> toggleSounds() async {
    final next = !state.soundsEnabled;
    await _service.setSoundsEnabled(next);
    state = state.copyWith(soundsEnabled: next);
  }

  Future<void> toggleNotifications() async {
    final next = !state.notificationsEnabled;
    await _service.setNotificationsEnabled(next);
    state = state.copyWith(notificationsEnabled: next);
  }
}

final passengerSettingsServiceProvider = Provider<PassengerSettingsService>(
  (ref) => PassengerSettingsService(),
);

final passengerSettingsProvider =
    StateNotifierProvider<PassengerSettingsNotifier, PassengerSettingsState>((
      ref,
    ) {
      final service = ref.watch(passengerSettingsServiceProvider);
      return PassengerSettingsNotifier(service);
    });
