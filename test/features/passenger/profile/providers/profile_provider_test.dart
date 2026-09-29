import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/repositories/passenger_profile_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/profile/providers/profile_dependencies.dart';
import 'package:fraya_mobile/features/passenger/profile/providers/profile_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

void main() {
  test('photo upload refreshes passenger profile from backend', () async {
    final repository = _PassengerProfileRepositoryFake();
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(
        status: AuthStatus.authenticated,
        userData: const {'id': 24, 'firstNames': 'Awa'},
      ),
    );
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWith((ref) => repository),
        passengerAuthProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(profileControllerProvider.notifier)
        .updateProfilePhoto(
          filePath: '/tmp/profile.jpg',
          fileName: 'profile.jpg',
        );

    expect(repository.updatePhotoCalls, 1);
    expect(repository.getProfileCalls, 1);
    expect(container.read(profileControllerProvider).success, isTrue);
    expect(
      container.read(passengerAuthProvider).userData?['profilePhoto'],
      '/uploads/passenger.jpg',
    );
  });

  test(
    'phone change requests OTP and updates local session on confirm',
    () async {
      final repository = _PassengerProfileRepositoryFake();
      final authNotifier = _PassengerAuthNotifierFake(
        AuthState(
          status: AuthStatus.authenticated,
          userData: {'id': 24, 'phoneNumber': '0100000000'},
        ),
      );
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWith((ref) => repository),
          passengerAuthProvider.overrideWith((ref) => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(profileControllerProvider.notifier);
      await controller.requestPhoneChange('0700000000');
      await controller.changePhone('0700000000', '1234');

      expect(repository.requestedPhoneNumbers, ['0700000000']);
      expect(repository.confirmationCodes, ['1234']);
      expect(
        container.read(passengerAuthProvider).userData?['phoneNumber'],
        '0700000000',
      );
      expect(container.read(profileControllerProvider).success, isTrue);
    },
  );

  test('failed confirmation keeps the previous local phone number', () async {
    final repository = _PassengerProfileRepositoryFake(
      confirmError: const ServerException(message: 'Code OTP invalide'),
    );
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(
        status: AuthStatus.authenticated,
        userData: {'id': 24, 'phoneNumber': '0100000000'},
      ),
    );
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWith((ref) => repository),
        passengerAuthProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(profileControllerProvider.notifier)
        .changePhone('0700000000', '0000');

    expect(
      container.read(passengerAuthProvider).userData?['phoneNumber'],
      '0100000000',
    );
    expect(
      container.read(profileControllerProvider).errorMessage,
      'Code OTP invalide',
    );
  });

  test(
    'duplicate phone conflict preserves message, status and session',
    () async {
      final repository = _PassengerProfileRepositoryFake(
        requestError: const ServerException(
          message: 'Ce numéro de téléphone est déjà utilisé',
          statusCode: 409,
        ),
      );
      final authNotifier = _PassengerAuthNotifierFake(
        AuthState(
          status: AuthStatus.authenticated,
          userData: {'id': 24, 'phoneNumber': '0100000000'},
        ),
      );
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWith((ref) => repository),
          passengerAuthProvider.overrideWith((ref) => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(profileControllerProvider.notifier)
          .requestPhoneChange('0700000000');

      final state = container.read(profileControllerProvider);
      expect(state.errorMessage, 'Ce numéro de téléphone est déjà utilisé');
      expect(state.errorStatusCode, 409);
      expect(repository.confirmationCodes, isEmpty);
      expect(
        container.read(passengerAuthProvider).userData?['phoneNumber'],
        '0100000000',
      );
    },
  );

  test('ignores a second phone change request while submitting', () async {
    final requestCompleter = Completer<void>();
    final repository = _PassengerProfileRepositoryFake(
      requestCompleter: requestCompleter,
    );
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWith((ref) => repository)],
    );
    final subscription = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(container.dispose);

    final controller = container.read(profileControllerProvider.notifier);
    final firstRequest = controller.requestPhoneChange('0700000000');
    await Future<void>.delayed(Duration.zero);
    await controller.requestPhoneChange('0500000000');

    expect(repository.requestedPhoneNumbers, ['0700000000']);

    requestCompleter.complete();
    await firstRequest;
  });
}

class _PassengerProfileRepositoryFake implements PassengerProfileRepository {
  _PassengerProfileRepositoryFake({
    this.confirmError,
    this.requestError,
    this.requestCompleter,
  });

  final Object? confirmError;
  final Object? requestError;
  final Completer<void>? requestCompleter;
  int updatePhotoCalls = 0;
  int getProfileCalls = 0;
  final requestedPhoneNumbers = <String>[];
  final confirmationCodes = <String>[];

  @override
  Future<Map<String, dynamic>> getProfile() async {
    getProfileCalls++;
    return const {
      'data': {
        'id': 24,
        'firstNames': 'Awa',
        'profilePhoto': '/uploads/passenger.jpg',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  }) {
    fail('Unexpected passenger profile update call.');
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
    await requestCompleter?.future;
  }

  @override
  Future<void> confirmPhoneChange(String verificationCode) async {
    confirmationCodes.add(verificationCode);
    if (confirmError != null) throw confirmError!;
  }
}

class _PassengerAuthNotifierFake extends PassengerAuthNotifier {
  _PassengerAuthNotifierFake(AuthState initialState)
    : super(
        loginUsecase: LoginPassengerUsecase(_PassengerAuthRepositoryFake()),
        registerStep1Usecase: RegisterStep1Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        registerStep2Usecase: RegisterStep2Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        registerStep3Usecase: RegisterStep3Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        logoutUsecase: LogoutPassengerUsecase(),
      ) {
    state = initialState;
  }

  @override
  Future<void> updateUserData(Map<String, dynamic> newData) async {
    final userData = Map<String, dynamic>.from(state.userData ?? const {});
    userData.addAll(newData);
    state = state.copyWith(userData: userData);
  }
}

class _PassengerAuthRepositoryFake extends PassengerAuthRepository {
  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String password) {
    fail('Unexpected passenger login call.');
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) {
    fail('Unexpected passenger register step 1 call.');
  }

  @override
  Future<void> registerStep2(String phoneNumber, String verificationCode) {
    fail('Unexpected passenger register step 2 call.');
  }

  @override
  Future<Map<String, dynamic>> registerStep3(Map<String, dynamic> userData) {
    fail('Unexpected passenger register step 3 call.');
  }
}
