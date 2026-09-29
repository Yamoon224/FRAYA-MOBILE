/// Configuration GoRouter — Navigation Passager
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/features/passenger/profile/screens/passenger_profile_screen.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../features/passenger/auth/screens/passenger_login_screen.dart';
import '../../features/passenger/auth/screens/passenger_register_screen.dart';
import '../../features/passenger/auth/screens/passenger_wrong_account_screen.dart';
import '../../features/passenger/home/screens/passenger_home_screen.dart';
import '../../features/passenger/booking/screens/route_preview_screen.dart';
import '../../features/passenger/booking/screens/ride_summary_screen.dart';
import '../../features/passenger/history/screens/my_rides_screen.dart';
import '../../features/passenger/history/details/screens/ride_details_screen.dart';
import '../../features/passenger/favorites/screens/favorites_screen.dart';
import '../../features/passenger/onboarding/screens/passenger_onboarding_screen.dart';
import '../../features/passenger/promotions/screens/passenger_promotions_screen.dart';
import '../../features/passenger/settings/screens/passenger_settings_screen.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../shared/screens/forgot_password_screen.dart';
import '../../shared/models/auth_state.dart';
import '../../data/sources/local_storage.dart';
import '../../core/utils/constants.dart';
import 'package:fraya_mobile/shared/widgets/fraya_skeleton.dart';
import '../../features/passenger/booking/providers/active_ride_check_provider.dart';
import '../../features/passenger/booking/providers/pending_search_session_provider.dart';
import 'route_names.dart';

class PassengerRouterNotifier extends ChangeNotifier {
  PassengerRouterNotifier(this.ref) {
    ref.listen(passengerAuthProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });

    ref.listen(activeRideCheckProvider, (previous, next) {
      if (next.hasValue) {
        notifyListeners();
      }
    });

    ref.listen(pendingSearchStartupCleanupProvider, (previous, next) {
      if (next.hasValue || next.hasError) {
        notifyListeners();
      }
    });
  }
  final Ref ref;
}

GoRouter createPassengerRouter(Ref ref) {
  final config = AppConfig.instance;

  final String initialLocation = RoutePaths.splash;

  final notifier = PassengerRouterNotifier(ref);

  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: config.enableLogging,
    refreshListenable: notifier,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeSkeleton()),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const PassengerOnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const PassengerLoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const PassengerRegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.passengerHome,
        name: RouteNames.passengerHome,
        builder: (context, state) => const PassengerHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.vehicleSelection,
        name: RouteNames.vehicleSelection,
        builder: (context, state) => const RoutePreviewScreen(),
      ),
      GoRoute(
        path: RoutePaths.rideTracking,
        name: RouteNames.rideTracking,
        builder: (context, state) => const RoutePreviewScreen(),
      ),
      GoRoute(
        path: RoutePaths.rideComplete,
        name: RouteNames.rideComplete,
        builder: (context, state) => const RideSummaryScreen(),
      ),
      GoRoute(
        path: RoutePaths.history,
        name: RouteNames.history,
        builder: (context, state) => const MyRidesScreen(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => const MyPassengerProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.rideDetails,
        name: RouteNames.rideDetails,
        builder: (context, state) {
          final rideId = state.uri.queryParameters['id'] ?? '';
          return RideDetailsScreen(rideId: rideId);
        },
      ),
      GoRoute(
        path: RoutePaths.favorites,
        name: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RoutePaths.promotions,
        name: RouteNames.promotions,
        builder: (context, state) => const PassengerPromotionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const PassengerSettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.passengerWrongAccount,
        name: RouteNames.passengerWrongAccount,
        builder: (context, state) => const PassengerWrongAccountScreen(),
      ),
    ],
    redirect: (context, state) {
      return resolvePassengerRedirect(
        authState: ref.read(passengerAuthProvider),
        currentPath: state.matchedLocation,
        hasCompletedOnboarding:
            LocalStorage.instance.getBool(AppConstants.onboardingCompleteKey) ??
            false,
        pendingSearchCleanupAsync: ref.read(
          pendingSearchStartupCleanupProvider,
        ),
        activeRideAsync: ref.read(activeRideCheckProvider),
      );
    },
    errorBuilder: (context, state) => _errorScreen(context, state),
  );
}

String? resolvePassengerRedirect({
  required AuthState authState,
  required String currentPath,
  required bool hasCompletedOnboarding,
  required AsyncValue pendingSearchCleanupAsync,
  required AsyncValue activeRideAsync,
}) {
  if (authState.status == AuthStatus.wrongRole) {
    return currentPath == RoutePaths.passengerWrongAccount
        ? null
        : RoutePaths.passengerWrongAccount;
  }

  if (authState.status == AuthStatus.idle) {
    return null;
  }

  final isAuthenticated = authState.status == AuthStatus.authenticated;
  final isAtSplash = currentPath == RoutePaths.splash;
  final isGoingToAuth =
      currentPath == RoutePaths.login ||
      currentPath == RoutePaths.register ||
      currentPath == RoutePaths.onboarding ||
      currentPath == RoutePaths.forgotPassword;

  if (isAtSplash && isAuthenticated) {
    if (pendingSearchCleanupAsync.isLoading) return null;
    return activeRideAsync.when(
      data: (ride) =>
          ride != null ? RoutePaths.vehicleSelection : RoutePaths.passengerHome,
      loading: () => null,
      error: (_, _) => RoutePaths.passengerHome,
    );
  }

  if (!isAuthenticated && (!isGoingToAuth || isAtSplash)) {
    return hasCompletedOnboarding ? RoutePaths.login : RoutePaths.onboarding;
  }

  if (isAuthenticated && isGoingToAuth) {
    return RoutePaths.passengerHome;
  }

  return null;
}

Widget _errorScreen(BuildContext context, GoRouterState state) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Page introuvable (Passager)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.uri.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
