import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/error/failures.dart';
import 'package:fraya_mobile/domain/repositories/driver_auth_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/login_driver_usecase.dart';

class RecordingDriverAuthRepository implements DriverAuthRepository {
  String? lastPhoneNumber;
  String? lastPassword;
  Map<String, dynamic> response = const {
    'data': {
      'access_token': 'driver-token',
      'user': {'id': 14},
    },
  };
  Object? error;

  @override
  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    if (error != null) {
      throw error!;
    }
    lastPhoneNumber = phoneNumber;
    lastPassword = password;
    return response;
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) {
    throw UnimplementedError();
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) {
    throw UnimplementedError();
  }

  @override
  Future<void> registerStep2(String phoneNumber, String verificationCode) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchProfile() {
    throw UnimplementedError();
  }
}

void main() {
  group('LoginDriverUseCase', () {
    test('forwards phone number and password to repository', () async {
      final repository = RecordingDriverAuthRepository();
      final useCase = LoginDriverUseCase(repository);

      final result = await useCase(
        const LoginDriverParams(phoneNumber: '0700000000', password: 'secret'),
      );

      expect(result.isRight(), isTrue);
      expect(repository.lastPhoneNumber, '0700000000');
      expect(repository.lastPassword, 'secret');
    });

    test('maps auth exceptions to auth failures', () async {
      final repository = RecordingDriverAuthRepository()
        ..error = const AuthException(
          message: 'Numéro ou mot de passe incorrect.',
        );
      final useCase = LoginDriverUseCase(repository);

      final result = await useCase(
        const LoginDriverParams(phoneNumber: '0700000000', password: 'secret'),
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Numéro ou mot de passe incorrect.');
      }, (_) => fail('Expected an auth failure'));
    });
  });
}
