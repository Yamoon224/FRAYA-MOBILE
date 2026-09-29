import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/repositories/driver_profile_repository.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/profile/providers/driver_profile_dependencies.dart';
import 'package:fraya_mobile/features/driver/profile/providers/driver_profile_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  test('photo upload refreshes driver profile from backend', () async {
    final repository = _DriverProfileRepositoryFake();
    final authNotifier = _RefreshingDriverAuthNotifier(
      AuthState(
        status: AuthStatus.authenticated,
        userData: const {'id': 18, 'firstNames': 'Boris'},
      ),
    );
    final container = ProviderContainer(
      overrides: [
        driverProfileRepositoryProvider.overrideWith((ref) => repository),
        driverAuthProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(driverProfileControllerProvider.notifier)
        .updateProfilePhoto(
          filePath: '/tmp/driver.jpg',
          fileName: 'driver.jpg',
        );

    expect(repository.updatePhotoCalls, 1);
    expect(authNotifier.refreshProfileCalls, 1);
    expect(container.read(driverProfileControllerProvider).success, isTrue);
    expect(
      container.read(driverAuthProvider).userData?['profilePhoto'],
      '/uploads/driver.jpg',
    );
  });

  test(
    'phone change requests OTP and updates local session on confirm',
    () async {
      final repository = _DriverProfileRepositoryFake();
      final authNotifier = _RefreshingDriverAuthNotifier(
        AuthState(
          status: AuthStatus.authenticated,
          userData: {'id': 18, 'phoneNumber': '0100000000'},
        ),
      );
      final container = ProviderContainer(
        overrides: [
          driverProfileRepositoryProvider.overrideWith((ref) => repository),
          driverAuthProvider.overrideWith((ref) => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        driverProfileControllerProvider.notifier,
      );
      await controller.requestPhoneChange('0700000000');
      await controller.changePhone('0700000000', '1234');

      expect(repository.requestedPhoneNumbers, ['0700000000']);
      expect(repository.confirmationCodes, ['1234']);
      expect(
        container.read(driverAuthProvider).userData?['phoneNumber'],
        '0700000000',
      );
      expect(container.read(driverProfileControllerProvider).success, isTrue);
    },
  );

  test(
    'duplicate phone conflict preserves message, status and session',
    () async {
      final repository = _DriverProfileRepositoryFake()
        ..requestError = const ServerException(
          message: 'Ce numéro de téléphone est déjà utilisé',
          statusCode: 409,
        );
      final authNotifier = _RefreshingDriverAuthNotifier(
        AuthState(
          status: AuthStatus.authenticated,
          userData: {'id': 18, 'phoneNumber': '0100000000'},
        ),
      );
      final container = ProviderContainer(
        overrides: [
          driverProfileRepositoryProvider.overrideWith((ref) => repository),
          driverAuthProvider.overrideWith((ref) => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(driverProfileControllerProvider.notifier)
          .requestPhoneChange('0700000000');

      final state = container.read(driverProfileControllerProvider);
      expect(state.errorMessage, 'Ce numéro de téléphone est déjà utilisé');
      expect(state.errorStatusCode, 409);
      expect(repository.confirmationCodes, isEmpty);
      expect(
        container.read(driverAuthProvider).userData?['phoneNumber'],
        '0100000000',
      );
    },
  );
}

class _DriverProfileRepositoryFake implements DriverProfileRepository {
  int updatePhotoCalls = 0;
  final requestedPhoneNumbers = <String>[];
  final confirmationCodes = <String>[];
  Object? requestError;

  @override
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  }) {
    fail('Unexpected driver profile update call.');
  }

  @override
  Future<Map<String, dynamic>> updateProfilePhoto({
    required int userId,
    required String filePath,
    required String fileName,
  }) async {
    updatePhotoCalls++;
    return const {};
  }

  @override
  Future<void> requestPhoneChange(String newPhoneNumber) async {
    requestedPhoneNumbers.add(newPhoneNumber);
    if (requestError != null) throw requestError!;
  }

  @override
  Future<void> confirmPhoneChange(String verificationCode) async {
    confirmationCodes.add(verificationCode);
  }
}

class _RefreshingDriverAuthNotifier extends FakeDriverAuthNotifier {
  _RefreshingDriverAuthNotifier(super.initialState);

  @override
  Future<void> updateUserData(Map<String, dynamic> newData) async {
    final userData = Map<String, dynamic>.from(state.userData ?? const {});
    userData.addAll(newData);
    state = state.copyWith(userData: userData);
  }

  @override
  Future<void> refreshProfile() async {
    refreshProfileCalls++;
    await updateUserData({'profilePhoto': '/uploads/driver.jpg'});
  }
}
