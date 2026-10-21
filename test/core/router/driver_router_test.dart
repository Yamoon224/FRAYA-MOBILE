import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/router/driver_router.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

void main() {
  group('resolveDriverRedirect', () {
    test('keeps splash while driver auth session is bootstrapping', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(status: AuthStatus.idle),
        currentPath: RoutePaths.splash,
      );

      expect(redirect, isNull);
    });

    test('redirects splash to login when unauthenticated', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(status: AuthStatus.unauthenticated),
        currentPath: RoutePaths.splash,
      );

      expect(redirect, RoutePaths.login);
    });

    test('redirects unauthenticated users to login for protected routes', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(status: AuthStatus.unauthenticated),
        currentPath: RoutePaths.driverHome,
      );

      expect(redirect, RoutePaths.login);
    });

    test('redirects to login on protected route after logout', () {
      final redirectBeforeLogout = resolveDriverRedirect(
        authState: _approvedAuthState,
        currentPath: RoutePaths.driverHome,
      );
      final redirectAfterLogout = resolveDriverRedirect(
        authState: AuthState(status: AuthStatus.unauthenticated),
        currentPath: RoutePaths.driverHome,
      );

      expect(redirectBeforeLogout, isNull);
      expect(redirectAfterLogout, RoutePaths.login);
    });

    test('redirects drivers without KYC submission to the single registration page', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {'driverId': 14, 'kycStatus': 'NOT_SUBMITTED'},
        ),
        currentPath: RoutePaths.driverHome,
      );

      expect(redirect, RoutePaths.driverVehicle);
    });

    test('keeps drivers on the single registration page while KYC is not submitted', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {'driverId': 14, 'kycStatus': 'NOT_SUBMITTED'},
        ),
        currentPath: RoutePaths.driverVehicle,
      );

      expect(redirect, isNull);
    });

    test('sends the old KYC route to the single registration page for new drivers', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {'driverId': 14, 'kycStatus': 'NOT_SUBMITTED'},
        ),
        currentPath: RoutePaths.driverKyc,
      );

      expect(redirect, RoutePaths.driverVehicle);
    });

    test('keeps the existing correction screen after a KYC rejection', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {'driverId': 14, 'kycStatus': 'REJECTED'},
        ),
        currentPath: RoutePaths.driverHome,
      );
      final onKyc = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {'driverId': 14, 'kycStatus': 'REJECTED'},
        ),
        currentPath: RoutePaths.driverKyc,
      );

      expect(redirect, RoutePaths.driverKyc);
      expect(onKyc, isNull);
    });

    test('redirects KYC pending drivers without vehicle to vehicle form', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {
            'driverId': 14,
            'kycStatus': 'PENDING_VALIDATION',
            'vehicleStatus': 'NOT_SUBMITTED',
          },
        ),
        currentPath: RoutePaths.driverHome,
      );

      expect(redirect, RoutePaths.driverVehicle);
    });

    test(
      'redirects approved KYC drivers with pending vehicle to waiting screen',
      () {
        final redirect = resolveDriverRedirect(
          authState: AuthState(
            status: AuthStatus.authenticated,
            userData: const {
              'driverId': 14,
              'kycStatus': 'APPROVED',
              'vehicleStatus': 'PENDING_VALIDATION',
              'vehicleId': 7,
            },
          ),
          currentPath: RoutePaths.driverHome,
        );

        expect(redirect, RoutePaths.driverVehiclePending);
      },
    );

    test('redirects submitted KYC pending drivers to waiting screen', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {
            'driverId': 14,
            'kycStatus': 'PENDING_VALIDATION',
            'vehicleStatus': 'APPROVED',
            'vehicleId': 7,
          },
        ),
        currentPath: RoutePaths.driverHome,
      );

      expect(redirect, RoutePaths.driverVehiclePending);
    });

    test(
      'redirects pending KYC drivers with existing approved vehicle to waiting screen',
      () {
        final redirect = resolveDriverRedirect(
          authState: AuthState(
            status: AuthStatus.authenticated,
            userData: const {
              'driverId': 14,
              'kycStatus': 'PENDING_VALIDATION',
              'vehicleStatus': 'APPROVED',
              'vehicleId': 7,
            },
          ),
          currentPath: RoutePaths.driverHome,
        );

        expect(redirect, RoutePaths.driverVehiclePending);
      },
    );

    test(
      'redirects pending drivers to waiting screen when vehicle KYC documents are complete',
      () {
        final redirect = resolveDriverRedirect(
          authState: AuthState(
            status: AuthStatus.authenticated,
            userData: const {
              'driverId': 14,
              'kycStatus': 'PENDING_VALIDATION',
              'vehicleStatus': 'PENDING_VALIDATION',
              'vehicleId': 7,
              'kycs': [
                {
                  'id': 6,
                  'status': 'PENDING_VALIDATION',
                  'insuranceCertificate': 'insurance.pdf',
                  'technicalInspection': 'inspection.pdf',
                  'vehicleRegistration': 'registration.pdf',
                  'photoFrontVehicle': 'front.jpg',
                },
              ],
            },
          ),
          currentPath: RoutePaths.driverHome,
        );

        expect(redirect, RoutePaths.driverVehiclePending);
      },
    );

    test('keeps submitted pending drivers on waiting screen', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {
            'driverId': 14,
            'kycStatus': 'APPROVED',
            'vehicleStatus': 'PENDING_VALIDATION',
            'vehicleId': 7,
          },
        ),
        currentPath: RoutePaths.driverVehiclePending,
      );

      expect(redirect, isNull);
    });

    test('redirects rejected vehicle submissions back to vehicle form', () {
      final redirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {
            'driverId': 14,
            'kycStatus': 'PENDING_VALIDATION',
            'vehicleStatus': 'REJECTED',
            'vehicleId': 7,
          },
        ),
        currentPath: RoutePaths.driverVehiclePending,
      );

      expect(redirect, RoutePaths.driverVehicle);
    });

    test('keeps fully approved drivers on home', () {
      final redirect = resolveDriverRedirect(
        authState: _approvedAuthState,
        currentPath: RoutePaths.driverHome,
      );

      expect(redirect, isNull);
    });

    test('redirects authenticated approved drivers from splash to home', () {
      final redirect = resolveDriverRedirect(
        authState: _approvedAuthState,
        currentPath: RoutePaths.splash,
      );

      expect(redirect, RoutePaths.driverHome);
    });

    test(
      'keeps authenticated approved drivers on wallet and profile routes',
      () {
        final walletRedirect = resolveDriverRedirect(
          authState: _approvedAuthState,
          currentPath: RoutePaths.driverWallet,
        );
        final profileRedirect = resolveDriverRedirect(
          authState: _approvedAuthState,
          currentPath: RoutePaths.driverProfile,
        );
        final settingsRedirect = resolveDriverRedirect(
          authState: _approvedAuthState,
          currentPath: RoutePaths.driverSettings,
        );

        expect(walletRedirect, isNull);
        expect(profileRedirect, isNull);
        expect(settingsRedirect, isNull);
      },
    );

    test('redirects login and register to the correct authenticated step', () {
      final homeRedirect = resolveDriverRedirect(
        authState: _approvedAuthState,
        currentPath: RoutePaths.login,
      );
      final vehicleRedirect = resolveDriverRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {
            'driverId': 14,
            'kycStatus': 'APPROVED',
            'vehicleStatus': 'NOT_SUBMITTED',
          },
        ),
        currentPath: RoutePaths.register,
      );

      expect(homeRedirect, RoutePaths.driverHome);
      expect(vehicleRedirect, RoutePaths.driverVehicle);
    });

    test('redirects approved drivers away from waiting screen to home', () {
      final redirect = resolveDriverRedirect(
        authState: _approvedAuthState,
        currentPath: RoutePaths.driverVehiclePending,
      );

      expect(redirect, RoutePaths.driverHome);
    });
  });
}

final _approvedAuthState = AuthState(
  status: AuthStatus.authenticated,
  userData: const {
    'driverId': 14,
    'kycStatus': 'APPROVED',
    'vehicleStatus': 'APPROVED',
    'vehicleId': 7,
  },
);
