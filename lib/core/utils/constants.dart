/// Constantes globales de l'application.
library;

abstract final class AppConstants {
  // ── Timeouts ──
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Storage Keys ──
  static const String accessTokenKey = 'access_token';
  static const String authUserDataKey = 'auth_user_data';
  static const String driverAccessTokenKey = 'driver_access_token';
  static const String driverAuthUserDataKey = 'driver_auth_user_data';
  static const String refreshTokenKey = 'refresh_token';
  static const String userTypeKey = 'user_type';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String pushPermissionRequestedKey = 'push_permission_requested';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String activeRideIdKey = 'active_ride_id';
  static const String activeDeviceRegistrationKey =
      'active_device_registration';
  static const String pendingSearchRideIdKey = 'pending_search_ride_id';
  static const String pendingSearchStartedAtKey =
      'pending_search_started_at_ms';
  static const String passengerBookingSessionKey = 'passenger_booking_session';
  static const String passengerRegisterDraftKey = 'passenger_register_draft';
  static const String driverRegisterDraftKey = 'driver_register_draft';
  static const String driverOnboardingDraftKey = 'driver_onboarding_draft';
  static const String driverOnboardingDraftDirectory = 'driver_onboarding';
  static const String driverIgnoredRideIdsKeyPrefix =
      'driver_ignored_ride_ids_';
  static const String driverWalletCommissionNoticeDismissedKey =
      'driver_wallet_commission_notice_dismissed';

  // ── Pagination ──
  static const int defaultPageSize = 20;

  // ── Validation ──
  static const int otpLength = 6;
  static const int phoneMinLength = 10;
  static const int phoneMaxLength = 15;

  // ── Monnaie ──
  static const String currency = 'FCFA';
  static const String currencyCode = 'XOF';

  // ── Localisation Abidjan ──
  static const double abidjanLat = 5.3600;
  static const double abidjanLng = -4.0083;
  static const double defaultMapZoom = 14.0;

  // ── Ride ──
  static const Duration driverSearchTimeout = Duration(minutes: 2);
  static const int maxMatchingAttempts = 5;
  static const double driverAvailableRidesRadiusKm = 8.0;
  static const double driverPreArrivalOffersRadiusMeters = 1000.0;
  static const double driverDestinationArrivalRadiusMeters = 30.0;
  static const double driverDestinationArrivalExitRadiusMeters = 45.0;
  static const Duration driverDestinationArrivalPromptCooldown = Duration(
    minutes: 3,
  );
}
