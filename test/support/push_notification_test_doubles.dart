import 'dart:async';

import 'package:fraya_mobile/core/services/push_notification_service.dart';
import 'package:fraya_mobile/domain/models/device_registration.dart';
import 'package:fraya_mobile/domain/repositories/device_registration_repository.dart';

class FakePushNotificationService implements PushNotificationService {
  FakePushNotificationService({
    required this.log,
    String? subscriptionId,
    Completer<void>? initializationCompleter,
  }) : _subscriptionId = subscriptionId,
       _initializationCompleter = initializationCompleter;

  final List<String> log;
  final _tapController = StreamController<PushNotificationPayload>.broadcast();
  final _receivedController =
      StreamController<PushNotificationPayload>.broadcast();
  final _subscriptionController = StreamController<String>.broadcast();
  final loginCalls = <String>[];
  final Completer<void>? _initializationCompleter;
  String? _subscriptionId;
  bool _hasPermission = true;
  bool _isOptedIn = true;

  @override
  Stream<PushNotificationPayload> get onNotificationTap =>
      _tapController.stream;

  @override
  Stream<PushNotificationPayload> get onNotificationReceived =>
      _receivedController.stream;

  @override
  Stream<String> get onSubscriptionChanged => _subscriptionController.stream;

  @override
  String? get currentSubscriptionId => _subscriptionId;

  @override
  bool get hasNotificationPermission => _hasPermission;

  @override
  bool get isPushSubscriptionOptedIn => _isOptedIn;

  @override
  Future<void> init() async {
    log.add('push.init');
    await _initializationCompleter?.future;
  }

  @override
  void markAppReady() {}

  @override
  Future<void> loginUser(String externalId) async {
    loginCalls.add(externalId);
    log.add('push.login:$externalId');
  }

  @override
  Future<void> logoutUser() async {
    log.add('push.logout');
  }

  @override
  Future<void> optInUser() async {
    _isOptedIn = true;
    log.add('push.optIn');
  }

  @override
  Future<bool> requestPermission() async {
    _hasPermission = true;
    log.add('push.permission');
    return true;
  }

  @override
  void setForegroundDisplayEnabled(bool enabled) {}

  void emitSubscription(String subscriptionId) {
    _subscriptionId = subscriptionId;
    _subscriptionController.add(subscriptionId);
  }

  void dispose() {
    _tapController.close();
    _receivedController.close();
    _subscriptionController.close();
  }
}

class RecordingDeviceRegistrationRepository
    implements DeviceRegistrationRepository {
  RecordingDeviceRegistrationRepository(this.log);

  final List<String> log;
  final registered = <DeviceRegistration>[];
  final deactivated = <DeviceRegistration>[];
  DeviceRegistration? _lastRegistration;

  @override
  Future<void> register(DeviceRegistration registration) async {
    registered.add(registration);
    log.add('device.register:${registration.userId}');
  }

  @override
  Future<void> deactivate(DeviceRegistration registration) async {
    deactivated.add(registration);
    log.add('device.deactivate:${registration.userId}');
  }

  @override
  Future<DeviceRegistration?> getLastRegistration() async {
    return _lastRegistration;
  }

  @override
  Future<void> saveLastRegistration(DeviceRegistration registration) async {
    _lastRegistration = registration;
  }

  @override
  Future<void> clearLastRegistration() async {
    _lastRegistration = null;
  }
}
