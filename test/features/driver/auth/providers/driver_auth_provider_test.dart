import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_submission.dart';
import 'package:fraya_mobile/domain/repositories/driver_auth_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_kyc_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/login_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/logout_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/refresh_driver_profile_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/kyc/get_driver_kyc_by_sid_user_usecase.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_local_session.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_session_parser.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_submission_review_info.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingDriverAuthRepository implements DriverAuthRepository {
  Map<String, dynamic> loginResponse = const {
    'data': {
      'access_token': 'driver-token',
      'user': {'id': 18, 'isDriver': true, 'kycStatus': 'APPROVED'},
    },
  };
  Map<String, dynamic> profileResponse = const {
    'data': {
      'id': 18,
      'kycStatus': 'APPROVED',
      'vehicleStatus': 'APPROVED',
      'vehicle': {'id': 4, 'vehicleStatus': 'APPROVED'},
    },
  };
  Completer<Map<String, dynamic>>? profileCompleter;
  Object? profileError;

  @override
  Future<Map<String, dynamic>> fetchProfile() async {
    if (profileError != null) throw profileError!;
    if (profileCompleter != null) return profileCompleter!.future;
    return profileResponse;
  }

  @override
  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    return loginResponse;
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    throw UnimplementedError();
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> registerStep2(
    String phoneNumber,
    String verificationCode,
  ) async {
    throw UnimplementedError();
  }
}

class _MemoryDriverAuthLocalSession extends DriverAuthLocalSession {
  _MemoryDriverAuthLocalSession({this.restoredUserData});

  Map<String, dynamic>? restoredUserData;

  @override
  Future<void> persist(String token, Map<String, dynamic> userData) async {}

  @override
  Future<Map<String, dynamic>?> restore() async {
    final restored = restoredUserData;
    if (restored == null) return null;
    return DriverAuthSessionParser.normalizeStoredUserData(restored);
  }
}

class _RecordingDriverKycRepository implements DriverKycRepository {
  Map<String, dynamic> response = const {'data': []};
  int? lastSidUserId;

  @override
  Future<Map<String, dynamic>> getKycBySidUser({required int sidUserId}) async {
    lastSidUserId = sidUserId;
    return response;
  }

  @override
  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required DriverKycSubmission submission,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> updateKyc({
    required int kycId,
    required Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  }) async {
    throw UnimplementedError();
  }
}

DriverAuthNotifier _buildNotifier(
  _RecordingDriverAuthRepository repository, {
  _RecordingDriverKycRepository? kycRepository,
  DriverAuthLocalSession? localSession,
  bool autoRestore = false,
}) {
  return DriverAuthNotifier(
    loginUseCase: LoginDriverUseCase(repository),
    registerUseCase: RegisterDriverUseCase(repository),
    registerStep1UseCase: RegisterDriverStep1UseCase(repository),
    registerStep2UseCase: RegisterDriverStep2UseCase(repository),
    logoutUseCase: LogoutDriverUseCase(),
    refreshProfileUseCase: RefreshDriverProfileUseCase(repository),
    getKycBySidUserUseCase: kycRepository == null
        ? null
        : GetDriverKycBySidUserUseCase(kycRepository),
    localSession: localSession ?? _MemoryDriverAuthLocalSession(),
    autoRestore: autoRestore,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  group('DriverAuthNotifier', () {
    test(
      'keeps loading until refreshed profile is merged after login',
      () async {
        final repository = _RecordingDriverAuthRepository()
          ..profileCompleter = Completer<Map<String, dynamic>>();
        final notifier = _buildNotifier(repository);

        final loginFuture = notifier.login('0700000000', 'secret');
        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.status, AuthStatus.loading);

        repository.profileCompleter!.complete(repository.profileResponse);
        await loginFuture;

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.userData?['vehicleId'], 4);
        expect(notifier.state.userData?['vehicleStatus'], 'APPROVED');
      },
    );

    test('falls back to login payload when profile refresh fails', () async {
      final repository = _RecordingDriverAuthRepository()
        ..profileError = const ServerException(message: 'network down');
      final notifier = _buildNotifier(repository);

      await notifier.login('0700000000', 'secret');

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.userData?['driverId'], 18);
      expect(notifier.state.userData?['vehicleId'], isNull);
    });

    test('keeps idle while restored session is being refreshed', () async {
      final repository = _RecordingDriverAuthRepository()
        ..profileCompleter = Completer<Map<String, dynamic>>();
      final localSession = _MemoryDriverAuthLocalSession(
        restoredUserData: const {'id': 18, 'kycStatus': 'APPROVED'},
      );

      final notifier = _buildNotifier(
        repository,
        localSession: localSession,
        autoRestore: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, AuthStatus.idle);

      repository.profileCompleter!.complete(repository.profileResponse);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.userData?['vehicleId'], 4);
    });

    test('enriches profile with latest KYC details by sid user id', () async {
      final repository = _RecordingDriverAuthRepository()
        ..profileResponse = const {
          'data': {
            'id': 37,
            'kycStatus': 'PENDING_VALIDATION',
            'vehicleStatus': 'NOT_SUBMITTED',
          },
        };
      final kycRepository = _RecordingDriverKycRepository()
        ..response = const {
          'data': [
            {
              'id': 6,
              'sidUserId': 37,
              'status': 'CANCEL',
              'description': 'Permis non conformes',
              'updateAt': '2026-06-17T17:34:17.690Z',
            },
          ],
        };
      final notifier = _buildNotifier(repository, kycRepository: kycRepository);

      await notifier.login('0700000000', 'secret');

      final userData = notifier.state.userData;
      final reviewInfo = DriverSubmissionReviewInfoResolver.fromUserData(
        userData,
      );
      expect(kycRepository.lastSidUserId, 37);
      expect(userData?['kycStatus'], 'REJECTED');
      expect(reviewInfo.kycId, 6);
      expect(reviewInfo.kycRejectionReason, 'Permis non conformes');
    });

    test(
      'keeps approved kyc status when refreshed profile omits kyc and latest kyc is unavailable',
      () async {
        final repository = _RecordingDriverAuthRepository()
          ..profileResponse = const {
            'data': {
              'id': 18,
              'vehicleStatus': 'APPROVED',
              'vehicle': {'id': 4, 'vehicleStatus': 'APPROVED'},
            },
          };
        final kycRepository = _RecordingDriverKycRepository()
          ..response = const {'data': []};
        final notifier = _buildNotifier(
          repository,
          kycRepository: kycRepository,
        );

        await notifier.login('0700000000', 'secret');

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.userData?['kycStatus'], 'APPROVED');
        expect(notifier.state.userData?['vehicleStatus'], 'APPROVED');
      },
    );

    test(
      'keeps approved vehicle status when refreshed profile omits vehicle status',
      () async {
        final repository = _RecordingDriverAuthRepository()
          ..loginResponse = const {
            'data': {
              'access_token': 'driver-token',
              'user': {
                'id': 18,
                'isDriver': true,
                'kycStatus': 'APPROVED',
                'vehicleStatus': 'APPROVED',
                'vehicle': {'id': 4, 'vehicleStatus': 'APPROVED'},
              },
            },
          }
          ..profileResponse = const {
            'data': {
              'id': 18,
              'kycStatus': 'APPROVED',
              'vehicle': {'id': 4},
            },
          };
        final notifier = _buildNotifier(repository);

        await notifier.login('0700000000', 'secret');

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.userData?['vehicleId'], 4);
        expect(notifier.state.userData?['vehicleStatus'], 'APPROVED');
      },
    );
  });
}
