import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/domain/models/device_registration.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/device_registration_provider.dart';
import 'package:fraya_mobile/shared/providers/push_notification_coordinator_provider.dart';
import 'package:fraya_mobile/shared/providers/push_notification_provider.dart';

import '../../support/driver_test_doubles.dart';
import '../../support/push_notification_test_doubles.dart';

void main() {
  setUp(() {
    AppConfig.instance.init(flavor: AppFlavor.driver);
  });

  tearDown(() {
    AppConfig.instance.init(flavor: AppFlavor.dev);
  });

  test(
    'registers authenticated driver device when subscription is available',
    () async {
      final log = <String>[];
      final repository = RecordingDeviceRegistrationRepository(log);
      final service = FakePushNotificationService(
        log: log,
        subscriptionId: 'sub-1',
      );
      final authNotifier = _authNotifier('24');
      final container = _container(
        service: service,
        repository: repository,
        authNotifier: authNotifier,
      );
      addTearDown(container.dispose);
      addTearDown(service.dispose);

      container.read(pushNotificationCoordinatorProvider);
      await _settle();

      expect(service.loginCalls, ['24']);
      expect(log.indexOf('push.init'), lessThan(log.indexOf('push.login:24')));
      expect(
        log.indexOf('push.init'),
        lessThan(log.indexOf('device.register:24')),
      );
      expect(repository.registered, const [
        DeviceRegistration(
          userId: '24',
          role: 'DRIVER',
          oneSignalSubscriptionId: 'sub-1',
          platform: 'android',
        ),
      ]);
    },
  );

  test('waits for push initialization before syncing the device', () async {
    final log = <String>[];
    final initializationCompleter = Completer<void>();
    final repository = RecordingDeviceRegistrationRepository(log);
    final service = FakePushNotificationService(
      log: log,
      subscriptionId: 'sub-1',
      initializationCompleter: initializationCompleter,
    );
    final container = _container(
      service: service,
      repository: repository,
      authNotifier: _authNotifier('24'),
    );
    addTearDown(container.dispose);
    addTearDown(service.dispose);

    container.read(pushNotificationCoordinatorProvider);
    await Future<void>.delayed(Duration.zero);

    expect(service.loginCalls, isEmpty);
    expect(repository.registered, isEmpty);

    initializationCompleter.complete();
    await _settle();

    expect(service.loginCalls, ['24']);
    expect(repository.registered, hasLength(1));
  });

  test('does not register when subscription is missing', () async {
    final log = <String>[];
    final repository = RecordingDeviceRegistrationRepository(log);
    final service = FakePushNotificationService(log: log);
    final authNotifier = _authNotifier('24');
    final container = _container(
      service: service,
      repository: repository,
      authNotifier: authNotifier,
    );
    addTearDown(container.dispose);
    addTearDown(service.dispose);

    container.read(pushNotificationCoordinatorProvider);
    await _settle();

    expect(service.loginCalls, ['24']);
    expect(repository.registered, isEmpty);
  });

  test('registers when subscription arrives after authentication', () async {
    final log = <String>[];
    final repository = RecordingDeviceRegistrationRepository(log);
    final service = FakePushNotificationService(log: log);
    final authNotifier = _authNotifier('24');
    final container = _container(
      service: service,
      repository: repository,
      authNotifier: authNotifier,
    );
    addTearDown(container.dispose);
    addTearDown(service.dispose);

    container.read(pushNotificationCoordinatorProvider);
    await _settle();
    service.emitSubscription('sub-late');
    await _settle();

    expect(repository.registered.map((item) => item.oneSignalSubscriptionId), [
      'sub-late',
    ]);
  });

  test('deactivates stored device before OneSignal logout', () async {
    final log = <String>[];
    final repository = RecordingDeviceRegistrationRepository(log);
    final service = FakePushNotificationService(
      log: log,
      subscriptionId: 'sub-1',
    );
    final authNotifier = _authNotifier('24');
    final container = _container(
      service: service,
      repository: repository,
      authNotifier: authNotifier,
    );
    addTearDown(container.dispose);
    addTearDown(service.dispose);

    container.read(pushNotificationCoordinatorProvider);
    await _settle();
    authNotifier.setTestState(AuthState(status: AuthStatus.unauthenticated));
    await _settle();

    expect(repository.deactivated.map((item) => item.userId), ['24']);
    expect(
      log.indexOf('device.deactivate:24'),
      lessThan(log.indexOf('push.logout')),
    );
  });

  test(
    'same device account change deactivates previous user then registers new user',
    () async {
      final log = <String>[];
      final repository = RecordingDeviceRegistrationRepository(log);
      final service = FakePushNotificationService(
        log: log,
        subscriptionId: 'sub-1',
      );
      final authNotifier = _authNotifier('24');
      final container = _container(
        service: service,
        repository: repository,
        authNotifier: authNotifier,
      );
      addTearDown(container.dispose);
      addTearDown(service.dispose);

      container.read(pushNotificationCoordinatorProvider);
      await _settle();
      authNotifier.setTestState(_driverAuthState('25'));
      await _settle();

      expect(repository.registered.map((item) => item.userId), ['24', '25']);
      expect(repository.deactivated.map((item) => item.userId), ['24']);
      expect(
        log.where(
          (entry) =>
              entry == 'device.deactivate:24' || entry == 'device.register:25',
        ),
        ['device.deactivate:24', 'device.register:25'],
      );
    },
  );
}

ProviderContainer _container({
  required FakePushNotificationService service,
  required RecordingDeviceRegistrationRepository repository,
  required FakeDriverAuthNotifier authNotifier,
}) {
  return ProviderContainer(
    overrides: [
      pushNotificationServiceProvider.overrideWith((ref) => service),
      deviceRegistrationRepositoryProvider.overrideWith((ref) => repository),
      deviceRegistrationPlatformProvider.overrideWith(
        (ref) =>
            () => 'android',
      ),
      driverAuthProvider.overrideWith((ref) => authNotifier),
    ],
  );
}

FakeDriverAuthNotifier _authNotifier(String userId) {
  return FakeDriverAuthNotifier(_driverAuthState(userId));
}

AuthState _driverAuthState(String userId) {
  return AuthState(
    status: AuthStatus.authenticated,
    userData: {'driverId': userId, 'id': userId, 'userId': userId},
  );
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}
