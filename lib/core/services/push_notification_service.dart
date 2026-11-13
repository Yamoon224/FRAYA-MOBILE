library;

export 'push_notification_payload.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/app_config.dart';
import '../utils/logger.dart';
import 'push_notification_payload.dart';

/// Canal Android des alertes : créé nativement (FrayaApplication.kt) et déclaré comme canal par défaut
/// des notifications FCM dans AndroidManifest.xml.
const String pushAlertsChannelId = 'fraya_alerts_v2';
const String _pushAlertsChannelName = 'Alertes Fraya';

/// Handler des messages reçus app fermée ou en arrière-plan. Doit être une fonction de premier niveau.
/// Les messages « notification » sont affichés par le système ; il n'y a rien d'autre à faire ici.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

/// Les valeurs `data` d'un message FCM sont toujours des chaînes : le serveur sérialise en JSON les valeurs
/// qui ne le sont pas. On les décode pour retrouver les mêmes structures qu'avant (ex. `data` imbriqué).
@visibleForTesting
Map<String, dynamic> decodeFcmData(Map<String, dynamic>? raw) {
  final decoded = <String, dynamic>{};
  if (raw == null) return decoded;
  raw.forEach((key, value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          decoded[key] = jsonDecode(trimmed);
          return;
        } catch (_) {
          // Texte ordinaire qui commence par « { » : on le garde tel quel.
        }
      }
    }
    decoded[key] = value;
  });
  return decoded;
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final StreamController<PushNotificationPayload> _tapController =
      StreamController<PushNotificationPayload>.broadcast();
  final StreamController<PushNotificationPayload> _receivedController =
      StreamController<PushNotificationPayload>.broadcast();
  final StreamController<String> _subscriptionController =
      StreamController<String>.broadcast();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initializationFuture;
  bool _isInitialized = false;
  bool _isConfigured = false;
  bool _appReady = false;
  bool _shouldDisplayForegroundNotifications = true;
  bool _permissionGranted = false;
  String? _token;
  int _localNotificationId = 0;
  PushNotificationPayload? _pendingTap;

  Stream<PushNotificationPayload> get onNotificationTap =>
      _tapController.stream;
  Stream<PushNotificationPayload> get onNotificationReceived =>
      _receivedController.stream;

  /// Émet le jeton FCM de l'appareil à chaque obtention ou renouvellement.
  Stream<String> get onSubscriptionChanged => _subscriptionController.stream;

  /// Jeton FCM courant (null tant qu'il n'est pas obtenu).
  String? get currentSubscriptionId => _token;

  bool get hasNotificationPermission => _isConfigured && _permissionGranted;

  bool get isPushSubscriptionOptedIn =>
      _isConfigured && _permissionGranted && (_token?.isNotEmpty ?? false);

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
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    // Le push est initialisé avant Crashlytics : Firebase peut ne pas l'être encore.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initializeLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    messaging.onTokenRefresh.listen(
      _handleToken,
      onError: (Object error, StackTrace stackTrace) {
        logger.warning('FCM: renouvellement du jeton en erreur', error);
      },
    );

    final settings = await messaging.getNotificationSettings();
    _permissionGranted = _isAuthorized(settings.authorizationStatus);

    _isConfigured = true;
    _isInitialized = true;
    logger.info('FCM initialise pour ${AppConfig.instance.appName}.');

    // Message qui a ouvert l'application depuis l'état fermé.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleMessageTap(initialMessage);

    if (_permissionGranted) await _fetchToken();
    _logDiagnosticState('init');
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
    // Si l'app a été lancée en touchant une notification locale affichée au premier plan.
    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      _handleLocalNotificationTap(response);
    }
  }

  void markAppReady() {
    _appReady = true;
    final pendingTap = _pendingTap;
    if (pendingTap == null) return;
    _pendingTap = null;
    _tapController.add(pendingTap);
  }

  /// FCM n'a pas de notion d'utilisateur connecté : l'association jeton ↔ utilisateur est faite côté
  /// serveur par l'enregistrement de l'appareil. On s'assure seulement d'avoir un jeton.
  Future<void> loginUser(String externalId) async {
    if (!_isConfigured || externalId.trim().isEmpty) return;
    if (_permissionGranted && (_token == null || _token!.isEmpty)) {
      await _fetchToken();
    }
    _logDiagnosticState('loginUser.after');
  }

  /// Supprime le jeton de l'appareil : un téléphone déconnecté ne doit plus recevoir de notifications.
  /// Un nouveau jeton sera généré à la prochaine connexion.
  Future<void> logoutUser() async {
    if (!_isConfigured) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      logger.warning('FCM: suppression du jeton impossible', error);
    }
    _token = null;
  }

  Future<bool> requestPermission() async {
    if (!_isInitialized) await init();
    if (!_isConfigured) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _permissionGranted = _isAuthorized(settings.authorizationStatus);
    if (_permissionGranted) await _fetchToken();
    _logDiagnosticState('requestPermission.after');
    return _permissionGranted;
  }

  /// Avec FCM, l'abonnement suit l'autorisation et le jeton : on (re)demande simplement le jeton.
  Future<void> optInUser() async {
    if (!_isConfigured || !_permissionGranted) return;
    await _fetchToken();
    _logDiagnosticState('optInUser.after');
  }

  void setForegroundDisplayEnabled(bool enabled) {
    _shouldDisplayForegroundNotifications = enabled;
  }

  bool _isAuthorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> _fetchToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      // Sur iOS le jeton FCM n'existe qu'une fois le jeton APNs reçu.
      if (!kIsWeb && Platform.isIOS) {
        final apns = await messaging.getAPNSToken();
        if (apns == null) {
          await Future<void>.delayed(const Duration(seconds: 2));
          if (await messaging.getAPNSToken() == null) {
            logger.warning('FCM: jeton APNs pas encore disponible.');
            return;
          }
        }
      }
      _handleToken(await messaging.getToken());
    } catch (error, stackTrace) {
      logger.warning('FCM: jeton indisponible', error, stackTrace);
    }
  }

  void _handleToken(String? token) {
    final trimmed = token?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    _token = trimmed;
    _subscriptionController.add(trimmed);
    _logDiagnosticState('tokenChange');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final payload = payloadFromRemoteMessage(message);
    _receivedController.add(payload);
    if (!_shouldDisplayForegroundNotifications) return;
    // iOS affiche lui-même la notification (setForegroundNotificationPresentationOptions) ;
    // Android ne le fait pas au premier plan.
    if (kIsWeb || !Platform.isAndroid) return;
    final title = payload.title;
    final body = payload.body;
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }
    unawaited(_showLocalNotification(title, body, message.data));
  }

  Future<void> _showLocalNotification(
    String? title,
    String? body,
    Map<String, dynamic> data,
  ) async {
    try {
      await _localNotifications.show(
        id: _localNotificationId++ & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            pushAlertsChannelId,
            _pushAlertsChannelName,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode({'title': title, 'body': body, 'data': data}),
      );
    } catch (error) {
      logger.warning('FCM: affichage de la notification impossible', error);
    }
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final data = decoded['data'];
      _dispatchTap(
        PushNotificationPayload.fromData(
          title: decoded['title']?.toString(),
          body: decoded['body']?.toString(),
          rawData: decodeFcmData(
            data is Map ? Map<String, dynamic>.from(data) : null,
          ),
        ),
      );
    } catch (error) {
      logger.warning('FCM: payload de notification illisible', error);
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    _dispatchTap(payloadFromRemoteMessage(message));
  }

  void _dispatchTap(PushNotificationPayload payload) {
    if (_appReady) {
      _tapController.add(payload);
      return;
    }
    _pendingTap = payload;
  }

  /// Convertit un message FCM en payload applicatif (titre/corps de la notification + data décodée).
  @visibleForTesting
  static PushNotificationPayload payloadFromRemoteMessage(
    RemoteMessage message,
  ) {
    return payloadFromFcm(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    );
  }

  @visibleForTesting
  static PushNotificationPayload payloadFromFcm({
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) {
    final decoded = decodeFcmData(data);
    return PushNotificationPayload.fromData(
      title: title ?? decoded['title']?.toString(),
      body: body ?? decoded['body']?.toString(),
      rawData: decoded.isEmpty ? null : decoded,
    );
  }

  void _logDiagnosticState(String source) {
    logger.info(
      'Diagnostic FCM [$source]: '
      'flavor=${AppConfig.instance.flavor.name}, '
      'permission=$_permissionGranted, '
      'token=${_maskValue(_token)}',
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
