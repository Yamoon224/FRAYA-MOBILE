import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/services/passenger_ride_alert_sound_service.dart';
import 'package:fraya_mobile/core/services/passenger_settings_service.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/settings/providers/passenger_settings_provider.dart';
import 'package:fraya_mobile/shared/providers/passenger_ride_alert_coordinator_provider.dart';
import 'package:fraya_mobile/shared/providers/passenger_ride_alert_sound_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
  });

  tearDown(() {
    AppConfig.instance.init(flavor: AppFlavor.dev);
  });

  test(
    'plays status sound even when in-app notifications are disabled',
    () async {
      final soundService = _RecordingPassengerRideAlertSoundService();
      final container = ProviderContainer(
        overrides: [
          activeRideCheckProvider.overrideWith((ref) async => null),
          bookingFlowProvider.overrideWithValue(
            BookingFlowState.driverAssigned,
          ),
          passengerRideAlertSoundServiceProvider.overrideWithValue(
            soundService,
          ),
          passengerSettingsProvider.overrideWith(
            (ref) => _TestPassengerSettingsNotifier(
              const PassengerSettingsState(
                soundsEnabled: true,
                notificationsEnabled: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(passengerRideAlertCoordinatorProvider);
      await container.read(activeRideCheckProvider.future);
      await Future<void>.delayed(Duration.zero);

      container
          .read(activeRideControllerProvider.notifier)
          .initialize(ActiveRide.mock.copyWith(status: RideStatus.accepted));
      await Future<void>.delayed(Duration.zero);

      expect(soundService.playCalls, 1);
    },
  );

  test(
    'does not play status sound while passenger settings are loading',
    () async {
      final soundService = _RecordingPassengerRideAlertSoundService();
      final container = ProviderContainer(
        overrides: [
          activeRideCheckProvider.overrideWith((ref) async => null),
          bookingFlowProvider.overrideWithValue(
            BookingFlowState.driverAssigned,
          ),
          passengerRideAlertSoundServiceProvider.overrideWithValue(
            soundService,
          ),
          passengerSettingsProvider.overrideWith(
            (ref) => _TestPassengerSettingsNotifier(
              const PassengerSettingsState(
                soundsEnabled: true,
                notificationsEnabled: true,
                isLoading: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(passengerRideAlertCoordinatorProvider);
      await container.read(activeRideCheckProvider.future);
      await Future<void>.delayed(Duration.zero);

      container
          .read(activeRideControllerProvider.notifier)
          .initialize(ActiveRide.mock.copyWith(status: RideStatus.accepted));
      await Future<void>.delayed(Duration.zero);

      expect(soundService.playCalls, 0);
    },
  );
}

class _RecordingPassengerRideAlertSoundService
    extends PassengerRideAlertSoundService {
  _RecordingPassengerRideAlertSoundService() : super.test();

  int playCalls = 0;

  @override
  Future<void> playAlert() async {
    playCalls++;
  }

  @override
  Future<void> dispose() async {}
}

class _TestPassengerSettingsNotifier extends PassengerSettingsNotifier {
  _TestPassengerSettingsNotifier(PassengerSettingsState initialState)
    : super(PassengerSettingsService()) {
    state = initialState;
  }

  @override
  Future<void> load() async {}
}
