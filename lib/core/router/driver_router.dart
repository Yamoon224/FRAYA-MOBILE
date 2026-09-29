/// Configuration GoRouter - Navigation Chauffeur
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../features/driver/auth/providers/driver_admin_status_gate.dart';
import '../../features/driver/auth/providers/driver_auth_provider.dart';
// import '../../features/driver/auth/providers/driver_kyc_vehicle_docs_resolver.dart'; // désactivé temporairement (voir b70ad34)
import '../../features/driver/auth/screens/driver_login_screen.dart';
import '../../features/driver/auth/screens/driver_register_screen.dart';
import '../../features/driver/earnings/screens/driver_earnings_screen.dart';
import '../../features/driver/history/screens/driver_history_screen.dart';
import '../../features/driver/home/screens/driver_home_screen.dart';
import '../../features/driver/kyc/screens/driver_kyc_screen.dart';
import '../../features/driver/profile/screens/driver_profile_screen.dart';
import '../../features/driver/settings/screens/driver_settings_screen.dart';
import '../../features/driver/status/screens/driver_ride_completion_screen.dart';
import '../../features/driver/vehicle/screens/driver_vehicle_pending_screen.dart';
import '../../features/driver/vehicle/screens/driver_vehicle_screen.dart';
import '../../features/driver/wallet/screens/driver_wallet_screen.dart';
import '../../features/driver/auth/screens/driver_wrong_account_screen.dart';
import '../../domain/models/driver_ride.dart';
import '../../shared/screens/forgot_password_screen.dart';
import '../../shared/models/auth_state.dart';
import '../../shared/widgets/fraya_skeleton.dart';
import 'route_names.dart';

class DriverRouterNotifier extends ChangeNotifier {
  DriverRouterNotifier(this.ref) {
    ref.listen(driverAuthProvider, (previous, next) {
      if (previous?.status != next.status ||
          previous?.userData != next.userData) {
        notifyListeners();
      }
    });
  }

  final Ref ref;
}

GoRouter createDriverRouter(Ref ref) {
  final config = AppConfig.instance;
  final notifier = DriverRouterNotifier(ref);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: config.enableLogging,
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const HomeSkeleton(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const DriverLoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const DriverRegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverHome,
        name: RouteNames.driverHome,
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverEarnings,
        name: RouteNames.driverEarnings,
        builder: (context, state) => const DriverEarningsScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverHistory,
        name: RouteNames.driverHistory,
        builder: (context, state) => const DriverHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverWallet,
        name: RouteNames.driverWallet,
        builder: (context, state) => const DriverWalletScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverProfile,
        name: RouteNames.driverProfile,
        builder: (context, state) => const DriverProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverSettings,
        name: RouteNames.driverSettings,
        builder: (context, state) => const DriverSettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverStatus,
        name: RouteNames.driverStatus,
        builder: (context, state) {
          final ride = state.extra;
          if (ride is! DriverRide) {
            return const _DriverRouteErrorScreen(
              title: 'Course introuvable',
              message: 'Impossible d\'ouvrir le flow de fin de course.',
            );
          }
          return DriverRideCompletionScreen(ride: ride);
        },
      ),
      GoRoute(
        path: RoutePaths.driverKyc,
        name: RouteNames.driverKyc,
        builder: (context, state) => const DriverKycScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverVehicle,
        name: RouteNames.driverVehicle,
        builder: (context, state) => const DriverVehicleScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverVehiclePending,
        name: RouteNames.driverVehiclePending,
        builder: (context, state) => const DriverVehiclePendingScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.driverWrongAccount,
        name: RouteNames.driverWrongAccount,
        builder: (context, state) => const DriverWrongAccountScreen(),
      ),
    ],
    redirect: (context, state) {
      return resolveDriverRedirect(
        authState: ref.read(driverAuthProvider),
        currentPath: state.matchedLocation,
      );
    },
    errorBuilder: (context, state) => _errorScreen(context, state),
  );
}

String? resolveDriverRedirect({
  required AuthState authState,
  required String currentPath,
}) {
  if (authState.status == AuthStatus.wrongRole) {
    return currentPath == RoutePaths.driverWrongAccount
        ? null
        : RoutePaths.driverWrongAccount;
  }

  if (authState.status == AuthStatus.idle) {
    return null;
  }

  final isAuthenticated = authState.status == AuthStatus.authenticated;
  final isGoingToAuth =
      currentPath == RoutePaths.login ||
      currentPath == RoutePaths.register ||
      currentPath == RoutePaths.forgotPassword;
  final isAtSplash = currentPath == RoutePaths.splash;
  final isGoingToKyc = currentPath == RoutePaths.driverKyc;
  final isGoingToVehicle = currentPath == RoutePaths.driverVehicle;
  final isGoingToVehiclePending =
      currentPath == RoutePaths.driverVehiclePending;

  if (!isAuthenticated && (!isGoingToAuth || isAtSplash)) {
    return RoutePaths.login;
  }

  if (!isAuthenticated) {
    return null;
  }

  final gate = DriverAdminStatusGate.fromUserData(authState.userData);
  if (gate.needsKycSubmission) {
    if (isGoingToKyc) return null;
    return RoutePaths.driverKyc;
  }

  // Désactivé temporairement (voir b70ad34) — réactiver si on dissocie docs véhicule KYC et formulaire véhicule
  // final vehicleKycDocs = DriverKycVehicleDocsResolver.resolve(
  //   authState.userData,
  // );
  // final needsVehicleKycCompletion =
  //     (gate.isKycPending || gate.isKycApproved) &&
  //     vehicleKycDocs.needsVehicleCompletion;
  // if (needsVehicleKycCompletion) {
  //   if (isGoingToKyc) return null;
  //   return RoutePaths.driverKyc;
  // }

  if (gate.isVehicleRejected) {
    if (isGoingToVehicle) return null;
    return RoutePaths.driverVehicle;
  }

  if (gate.isSubmittedAndPending) {
    if (isGoingToVehiclePending) return null;
    return RoutePaths.driverVehiclePending;
  }

  final needsVehicleStep = !gate.hasVehicleId || !gate.isVehicleApproved;

  if (needsVehicleStep && !isGoingToVehicle) {
    return RoutePaths.driverVehicle;
  }

  if (!gate.needsKycSubmission && !needsVehicleStep && isGoingToKyc) {
    return RoutePaths.driverHome;
  }

  if (!needsVehicleStep && (isGoingToVehicle || isGoingToVehiclePending)) {
    return RoutePaths.driverHome;
  }

  if (isAtSplash) {
    return RoutePaths.driverHome;
  }

  if (isGoingToAuth) {
    if (gate.needsKycSubmission) {
      return RoutePaths.driverKyc;
    }
    if (needsVehicleStep) {
      return RoutePaths.driverVehicle;
    }
    return RoutePaths.driverHome;
  }

  return null;
}

class _DriverRouteErrorScreen extends StatelessWidget {
  const _DriverRouteErrorScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _errorScreen(BuildContext context, GoRouterState state) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.black),
          const SizedBox(height: 16),
          Text(
            'Page introuvable (Chauffeur)',
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
