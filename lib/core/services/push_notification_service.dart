library;

export 'push_notification_payload.dart';

import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/app_config.dart';
import '../utils/logger.dart';
import 'push_notification_payload.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final StreamController<PushNotificationPayload> _tapController =
      StreamController<PushNotificationPayload>.broadcast();
  final StreamController<PushNotificationPayload> _receivedController =
      StreamController<PushNotificationPayload>.broadcast();
  final StreamController<String> _subscriptionController =
      StreamController<String>.broadcast();

  Future<void>? _initializationFuture;
  bool _isInitialized = false;
  bool _isConfigured = false;
  bool _appReady = false;
  bool _shouldDisplayForegroundNotifications = true;
  PushNotificationPayload? _pendingTap;

  Stream<PushNotificationPayload> get onNotificationTap =>
      _tapController.stream;
  Stream<PushNotificationPayload> get onNotificationReceived =>
      _receivedController.stream;
  Stream<String> get onSubscriptionChanged => _subscriptionController.stream;
  String? get currentSubscriptionId {
    if (!_isConfigured) return null;
    return OneSignal.User.pushSubscription.id;
  }

  bool get hasNotificationPermission {
    if (!_isConfigured) return false;
    return OneSignal.Notifications.permission;
  }

  bool get isPushSubscriptionOptedIn {
    if (!_isConfigured) return false;
    return OneSignal.User.pushSubscription.optedIn == true;
  }

  Future<void> init() {
    if (_isInitialized) return Future<void>.value();
    final pendingInitialization = _initializationFuture;
    if (pendingInitialization != null) return pendingInitialization;

    late final Future<void> initialization;
    initialization = Future<void>.microtask(_initialize).whenComplete(() {
      if (identical(_initializationFuture, initialization)) {
        _initializationFuture = null;
      }
    });
    _initializationFuture = initialization;
    return initialization;
  }

  Future<void> _initialize() async {
    final appId = _resolveAppId();
    if (appId.isEmpty) {
      logger.warning(
        'OneSignal non initialise: App ID manquant pour le flavor '
        '${AppConfig.instance.flavor.name}.',
      );
      _isInitialized = true;
      return;
    }

    await OneSignal.initialize(appId);
    OneSignal.Notifications.addForegroundWillDisplayListener(
      _handleForegroundNotification,
    );
    OneSignal.Notifications.addClickListener(_handleNotificationTap);
    OneSignal.User.pushSubscription.addObserver(_handleSubscriptionChange);

    final existingSubscriptionId = OneSignal.User.pushSubscription.id;
    if (existingSubscriptionId != null && existingSubscriptionId.isNotEmpty) {
      _subscriptionController.add(existingSubscriptionId);
    }

    _isConfigured = true;
    _isInitialized = true;
    logger.info('OneSignal initialise pour ${AppConfig.instance.appName}.');
    _logDiagnosticState('init', appId: appId);
  }

  void markAppReady() {
    _appReady = true;
    final pendingTap = _pendingTap;
    if (pendingTap == null) return;
    _pendingTap = null;
    _tapController.add(pendingTap);
  }

  Future<void> loginUser(String externalId) async {
    final trimmedExternalId = externalId.trim();
    if (!_isConfigured || trimmedExternalId.isEmpty) return;

    logger.warning(
      'Diagnostic OneSignal [loginUser.before]: '
      'externalId=${_maskValue(trimmedExternalId)}',
    );
    await OneSignal.login(trimmedExternalId);
    _logDiagnosticState('loginUser.after', externalId: trimmedExternalId);
  }

  Future<void> logoutUser() async {
    if (!_isConfigured) return;
    await OneSignal.User.pushSubscription.optOut();
    await OneSignal.logout();
  }

  Future<bool> requestPermission() async {
    if (!_isConfigured) return false;
    final granted = await OneSignal.Notifications.requestPermission(true);
    _logDiagnosticState('requestPermission.after');
    return granted;
  }

  Future<void> optInUser() async {
    if (!_isConfigured) return;
    await OneSignal.User.pushSubscription.optIn();
    _logDiagnosticState('optInUser.after');
  }

  void setForegroundDisplayEnabled(bool enabled) {
    _shouldDisplayForegroundNotifications = enabled;
  }

  void _handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    event.preventDefault();
    _receivedController.add(_payloadFromNotification(event.notification));
    if (_shouldDisplayForegroundNotifications) {
      event.notification.display();
    }
  }

  void _handleNotificationTap(OSNotificationClickEvent event) {
    final payload = _payloadFromNotification(event.notification);
    if (_appReady) {
      _tapController.add(payload);
      return;
    }
    _pendingTap = payload;
  }

  void _handleSubscriptionChange(OSPushSubscriptionChangedState state) {
    final id = state.current.id;
    if (id == null || id.isEmpty) return;
    _subscriptionController.add(id);
    _logDiagnosticState('subscriptionChange');
  }

  String _resolveAppId() {
    if (AppConfig.instance.isPassenger) {
      return dotenv.env['ONESIGNAL_APP_ID_PASSENGER']?.trim() ?? '';
    }
    if (AppConfig.instance.isDriver) {
      return dotenv.env['ONESIGNAL_APP_ID_DRIVER']?.trim() ?? '';
    }
    return '';
  }

  PushNotificationPayload _payloadFromNotification(
    OSNotification notification,
  ) {
    final data = notification.additionalData;
    final rawData = data == null ? null : Map<String, dynamic>.from(data);
    return PushNotificationPayload.fromData(
      title: notification.title,
      body: notification.body,
      rawData: rawData,
    );
  }

  void _logDiagnosticState(String source, {String? appId, String? externalId}) {
    final subscription = OneSignal.User.pushSubscription;
    logger.warning(
      'Diagnostic OneSignal [$source]: '
      'flavor=${AppConfig.instance.flavor.name}, '
      'appId=${_maskValue(appId)}, '
      'permission=${OneSignal.Notifications.permission}, '
      'subscriptionId=${_maskValue(subscription.id)}, '
      'token=${_maskValue(subscription.token)}, '
      'optedIn=${subscription.optedIn}, '
      'externalId=${_maskValue(externalId)}',
    );
  }

  String _maskValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'absent';
    if (trimmed.length <= 4) return 'present(len=${trimmed.length})';

    return '${trimmed.substring(0, 2)}...'
        '${trimmed.substring(trimmed.length - 2)}'
        '(len=${trimmed.length})';
  }
}
