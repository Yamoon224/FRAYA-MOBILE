/// Constantes des noms de routes.
library;

abstract final class RouteNames {
  // ── Auth ──
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String otp = 'otp';
  static const String profileSetup = 'profile-setup';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';

  // ── Passenger ──
  static const String passengerWrongAccount = 'passenger-wrong-account';
  static const String passengerHome = 'passenger-home';
  static const String destinationSearch = 'destination-search';
  static const String vehicleSelection = 'vehicle-selection';
  static const String rideTracking = 'ride-tracking';
  static const String rideComplete = 'ride-complete';
  static const String rideDetails = 'ride-details';
  static const String promotions = 'passenger-promotions';

  // ── Driver ──
  static const String driverWrongAccount = 'driver-wrong-account';
  static const String driverHome = 'driver-home';
  static const String driverKyc = 'driver-kyc';
  static const String driverVehicle = 'driver-vehicle';
  static const String driverVehiclePending = 'driver-vehicle-pending';
  static const String rideRequests = 'ride-requests';
  static const String driverEarnings = 'driver-earnings';
  static const String driverHistory = 'driver-history';
  static const String driverStatus = 'driver-status';
  static const String driverWallet = 'driver-wallet';
  static const String driverProfile = 'driver-profile';
  static const String driverSettings = 'driver-settings';

  // ── Communs ──
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String history = 'history';
  static const String wallet = 'wallet';
  static const String favorites = 'favorites';
}

/// Chemins des routes.
abstract final class RoutePaths {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String passengerWrongAccount = '/passenger/wrong-account';
  static const String passengerHome = '/passenger/home';
  static const String destinationSearch = '/passenger/search';
  static const String vehicleSelection = '/passenger/vehicle';
  static const String rideTracking = '/passenger/tracking';
  static const String rideComplete = '/passenger/complete';
  static const String rideDetails = '/passenger/ride-details';
  static const String promotions = '/passenger/promotions';

  static const String driverWrongAccount = '/driver/wrong-account';
  static const String driverHome = '/driver/home';
  static const String driverKyc = '/driver/kyc';
  static const String driverVehicle = '/driver/vehicle';
  static const String driverVehiclePending = '/driver/vehicle/pending';
  static const String rideRequests = '/driver/requests';
  static const String driverEarnings = '/driver/earnings';
  static const String driverHistory = '/driver/history';
  static const String driverStatus = '/driver/status';
  static const String driverWallet = '/driver/wallet';
  static const String driverProfile = '/driver/profile';
  static const String driverSettings = '/driver/settings';

  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String wallet = '/wallet';
  static const String favorites = '/passenger/favorites';
}
