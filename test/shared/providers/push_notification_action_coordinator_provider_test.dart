import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/core/services/push_notification_service.dart';
import 'package:fraya_mobile/shared/providers/push_notification_action_coordinator_provider.dart';
import 'package:fraya_mobile/shared/providers/push_notification_actions.dart';
import 'package:fraya_mobile/shared/providers/push_notification_provider.dart';

void main() {
  setUp(() {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
  });

  tearDown(() {
    AppConfig.instance.init(flavor: AppFlavor.dev);
  });

  test('passenger ride_accepted refreshes and navigates on tap', () async {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    final tapController = StreamController<PushNotificationPayload>.broadcast();
    final receivedController =
        StreamController<PushNotificationPayload>.broadcast();
    final actions = _PassengerActions();

    final container = _container(
      tapStream: tapController.stream,
      receivedStream: receivedController.stream,
      gate: const _Gate(passenger: true),
      passengerActions: actions,
    );
    addTearDown(container.dispose);
    addTearDown(tapController.close);
    addTearDown(receivedController.close);

    container.read(pushNotificationActionCoordinatorProvider);
    tapController.add(
      PushNotificationPayload.fromData(
        rawData: {
          'notificationId': 'n-1',
          'type': 'ride_accepted',
          'rideId': 123,
          'recipientRole': 'PASSENGER',
        },
      ),
    );
    await _settle();

    expect(actions.refreshedRideIds, ['123']);
    expect(actions.routes, [RouteNames.rideTracking]);
  });

  test('driver new_ride_available refreshes without in-app snackbar', () async {
    AppConfig.instance.init(flavor: AppFlavor.driver);
    final tapController = StreamController<PushNotificationPayload>.broadcast();
    final receivedController =
        StreamController<PushNotificationPayload>.broadcast();
    final actions = _DriverActions(isOnline: true);

    final container = _container(
      tapStream: tapController.stream,
      receivedStream: receivedController.stream,
      gate: const _Gate(driver: true),
      driverActions: actions,
    );
    addTearDown(container.dispose);
    addTearDown(tapController.close);
    addTearDown(receivedController.close);

    container.read(pushNotificationActionCoordinatorProvider);
    receivedController.add(
      PushNotificationPayload.fromData(
        rawData: {
          'type': 'new_ride_available',
          'rideId': 91,
          'recipientRole': 'DRIVER',
        },
      ),
    );
    await _settle();

    expect(actions.refreshCount, 1);
    expect(actions.alerts, isEmpty);
  });

  test('driver ride_cancelled is deduplicated by notification id', () async {
    AppConfig.instance.init(flavor: AppFlavor.driver);
    final tapController = StreamController<PushNotificationPayload>.broadcast();
    final receivedController =
        StreamController<PushNotificationPayload>.broadcast();
    final actions = _DriverActions(isOnline: true);

    final container = _container(
      tapStream: tapController.stream,
      receivedStream: receivedController.stream,
      gate: const _Gate(driver: true),
      driverActions: actions,
    );
    addTearDown(container.dispose);
    addTearDown(tapController.close);
    addTearDown(receivedController.close);

    container.read(pushNotificationActionCoordinatorProvider);
    final payload = PushNotificationPayload.fromData(
      body: 'Annulee par le passager',
      rawData: {
        'notificationId': 'same-id',
        'type': 'ride_cancelled',
        'rideId': 77,
        'recipientRole': 'DRIVER',
      },
    );
    receivedController.add(payload);
    tapController.add(payload);
    await _settle();

    expect(actions.refreshCount, 1);
    expect(actions.statuses, ['77:CANCELLED']);
    expect(actions.alerts, isEmpty);
    expect(actions.routes, isEmpty);
  });

  test('driver driver_rated refreshes data without in-app snackbar', () async {
    AppConfig.instance.init(flavor: AppFlavor.driver);
    final tapController = StreamController<PushNotificationPayload>.broadcast();
    final receivedController =
        StreamController<PushNotificationPayload>.broadcast();
    final actions = _DriverActions(isOnline: true);

    final container = _container(
      tapStream: tapController.stream,
      receivedStream: receivedController.stream,
      gate: const _Gate(driver: true),
      driverActions: actions,
    );
    addTearDown(container.dispose);
    addTearDown(tapController.close);
    addTearDown(receivedController.close);

    container.read(pushNotificationActionCoordinatorProvider);
    receivedController.add(
      PushNotificationPayload.fromData(
        body: 'Nouvelle note recue.',
        rawData: {
          'notificationId': 'rating-1',
          'type': 'driver_rated',
          'recipientRole': 'DRIVER',
        },
      ),
    );
    await _settle();

    expect(actions.historyInvalidations, 1);
    expect(actions.profileRefreshes, 1);
    expect(actions.alerts, isEmpty);
  });
}

ProviderContainer _container({
  required Stream<PushNotificationPayload> tapStream,
  required Stream<PushNotificationPayload> receivedStream,
  required PushNotificationAuthGate gate,
  PassengerPushNotificationActions? passengerActions,
  DriverPushNotificationActions? driverActions,
}) {
  return ProviderContainer(
    overrides: [
      pushNotificationTapStreamProvider.overrideWithValue(tapStream),
      pushNotificationReceivedStreamProvider.overrideWithValue(receivedStream),
      pushNotificationAuthGateProvider.overrideWithValue(gate),
      if (passengerActions != null)
        passengerPushNotificationActionsProvider.overrideWithValue(
          passengerActions,
        ),
      if (driverActions != null)
        driverPushNotificationActionsProvider.overrideWithValue(driverActions),
    ],
  );
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

class _Gate implements PushNotificationAuthGate {
  const _Gate({this.passenger = false, this.driver = false});

  final bool passenger;
  final bool driver;

  @override
  bool get isPassengerAuthenticated => passenger;

  @override
  bool get isDriverAuthenticated => driver;
}

class _PassengerActions implements PassengerPushNotificationActions {
  final refreshedRideIds = <String?>[];
  final alerts = <String>[];
  final routes = <String>[];
  bool _hasActiveRide = false;

  @override
  bool get hasActiveRide => _hasActiveRide;

  @override
  Future<void> refreshRide(String? rideId) async {
    refreshedRideIds.add(rideId);
    _hasActiveRide = true;
  }

  @override
  void clearActiveRide() {
    _hasActiveRide = false;
  }

  @override
  void showInfo(String message) => alerts.add(message);

  @override
  void goNamed(String routeName) => routes.add(routeName);
}

class _DriverActions implements DriverPushNotificationActions {
  _DriverActions({required this.isOnline});

  @override
  final bool isOnline;

  int refreshCount = 0;
  final statuses = <String>[];
  final alerts = <String>[];
  final routes = <String>[];
  int historyInvalidations = 0;
  int profileRefreshes = 0;

  @override
  Future<void> refreshHome() async {
    refreshCount++;
  }

  @override
  void emitRideStatus(PushNotificationPayload payload, String status) {
    statuses.add('${payload.rideId}:$status');
  }

  @override
  void invalidateHistory() {
    historyInvalidations++;
  }

  @override
  void refreshProfile() {
    profileRefreshes++;
  }

  @override
  void showInfo(String message) => alerts.add(message);

  @override
  void goNamed(String routeName) => routes.add(routeName);
}
