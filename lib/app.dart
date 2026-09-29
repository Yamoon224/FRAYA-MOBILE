/// Widget racine de l'application Fraya.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/services/auth_session_notifier.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/driver/home/providers/driver_home_provider.dart';
import 'features/driver/home/providers/driver_presence_controller.dart';
import 'features/driver/settings/providers/driver_settings_provider.dart';
import 'features/passenger/booking/providers/pending_search_session_provider.dart';
import 'features/passenger/settings/providers/passenger_settings_provider.dart';
import 'shared/providers/app_providers.dart';
import 'shared/providers/app_resume_refresh_provider.dart';
import 'shared/providers/auth_session_coordinator_provider.dart';
import 'shared/providers/passenger_ride_alert_coordinator_provider.dart';
import 'shared/providers/push_notification_action_coordinator_provider.dart';
import 'shared/providers/push_notification_coordinator_provider.dart';
import 'shared/providers/realtime_session_provider.dart';
import 'shared/widgets/app_snack_bar.dart';
import 'shared/widgets/app_startup_splash.dart';
import 'shared/widgets/completed_ride_summary_listener.dart';
import 'shared/widgets/global_app_alert_listener.dart';

class FrayaApp extends ConsumerStatefulWidget {
  const FrayaApp({super.key});

  @override
  ConsumerState<FrayaApp> createState() => _FrayaAppState();
}

class _FrayaAppState extends ConsumerState<FrayaApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<String?>? _sessionSub;
  StreamSubscription<PushNotificationPayload>? _pushTapSub;
  late final AppResumeRefreshLifecycleCoordinator _resumeRefreshCoordinator;

  @override
  void initState() {
    super.initState();
    _resumeRefreshCoordinator = AppResumeRefreshLifecycleCoordinator(
      threshold: () => ref.read(appResumeRefreshThresholdProvider),
      refreshAfterLongBackground: _refreshAfterLongBackground,
      dismissTransientAlerts: _dismissTransientAlerts,
      handleAppDetached: _handleAppDetached,
      handleAppResumed: _handleAppResumed,
      onError: (error, stackTrace) {
        logger.warning('Resume refresh failed', error, stackTrace);
      },
    );
    WidgetsBinding.instance.addObserver(_resumeRefreshCoordinator);
    _sessionSub = AuthSessionNotifier.instance.events.listen((message) async {
      final text = (message != null && message.trim().isNotEmpty)
          ? message
          : 'Votre session a expiré. Veuillez vous reconnecter.';

      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(text)),
      );
    });
    _pushTapSub = PushNotificationService.instance.onNotificationTap.listen(
      _handlePushTap,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.markAppReady();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_resumeRefreshCoordinator);
    _sessionSub?.cancel();
    _pushTapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeSessionProvider);
    ref.watch(authSessionCoordinatorProvider);
    ref.watch(pushNotificationCoordinatorProvider);
    ref.watch(pushNotificationActionCoordinatorProvider);
    ref.watch(passengerRideAlertCoordinatorProvider);
    _syncForegroundPushDisplay();
    if (AppConfig.instance.isPassenger) {
      ref.watch(passengerPendingSearchLifecycleProvider);
    } else if (AppConfig.instance.isDriver) {
      ref.watch(driverPresenceControllerProvider);
    }
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.instance.appName,
      debugShowCheckedModeBanner: AppConfig.instance.isDev,

      // Thème Fraya
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // Navigation
      routerConfig: router,
      scaffoldMessengerKey: _scaffoldMessengerKey,

      // Gestion du clavier : Fermer au clic extérieur
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
            ),
          ),
          child: AppStartupSplash(
            child: GestureDetector(
              onTap: () {
                final currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus &&
                    currentFocus.focusedChild != null) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              },
              child: GlobalAppAlertListener(
                child: CompletedRideSummaryListener(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },

      // Localisation
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  void _handlePushTap(PushNotificationPayload payload) {
    logger.info(
      'Push tap observe: type=${payload.type}, data=${payload.rawData}',
    );
  }

  void _dismissTransientAlerts() {
    _scaffoldMessengerKey.currentState
      ?..clearSnackBars()
      ..hideCurrentSnackBar();
    AppSnackBar.dismissCurrentTopOverlay();
  }

  Future<void> _refreshAfterLongBackground() async {
    await ref
        .read(appResumeRefreshActionsProvider)
        .refreshAfterLongBackground();
    if (!mounted) return;
    setState(() {
      // Root rebuild intentionally mirrors hot reload semantics: keep route and
      // widget state alive, but ask the tree to rebuild with refreshed data.
    });
  }

  Future<void> _handleAppDetached() async {
    if (!AppConfig.instance.isDriver) return;
    await ref.read(driverPresenceControllerProvider).handleAppDetached();
    await ref.read(driverHomeProvider.notifier).handleAppClosing();
  }

  Future<void> _handleAppResumed() async {
    if (!AppConfig.instance.isDriver) return;
    await ref.read(driverPresenceControllerProvider).handleAppResumed();
  }

  void _syncForegroundPushDisplay() {
    final service = PushNotificationService.instance;
    if (AppConfig.instance.isPassenger) {
      final settings = ref.watch(passengerSettingsProvider);
      service.setForegroundDisplayEnabled(
        !settings.isLoading && settings.notificationsEnabled,
      );
      return;
    }
    if (AppConfig.instance.isDriver) {
      final settings = ref.watch(driverSettingsProvider);
      service.setForegroundDisplayEnabled(
        !settings.isLoading && settings.notificationsEnabled,
      );
      return;
    }
    service.setForegroundDisplayEnabled(true);
  }
}
