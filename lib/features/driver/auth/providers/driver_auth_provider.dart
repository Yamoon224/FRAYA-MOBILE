import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_session_notifier.dart';
import '../../../../core/utils/constants.dart';
import '../../../../data/sources/local_storage.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../domain/usecases/driver/auth/login_driver_usecase.dart';
import '../../../../domain/usecases/driver/auth/logout_driver_usecase.dart';
import '../../../../domain/usecases/driver/auth/refresh_driver_profile_usecase.dart';
import '../../../../domain/usecases/driver/auth/register_driver_usecase.dart';
import '../../../../domain/usecases/driver/auth/register_driver_step1_usecase.dart';
import '../../../../domain/usecases/driver/auth/register_driver_step2_usecase.dart';
import '../../../../domain/usecases/driver/kyc/get_driver_kyc_by_sid_user_usecase.dart';
import '../../kyc/providers/driver_kyc_dependencies.dart';
import 'driver_auth_dependencies.dart';
import 'driver_auth_local_session.dart';
import 'driver_auth_session_parser.dart';

class DriverAuthNotifier extends StateNotifier<AuthState> {
  DriverAuthNotifier({
    required LoginDriverUseCase loginUseCase,
    required RegisterDriverUseCase registerUseCase,
    required RegisterDriverStep1UseCase registerStep1UseCase,
    required RegisterDriverStep2UseCase registerStep2UseCase,
    required LogoutDriverUseCase logoutUseCase,
    required RefreshDriverProfileUseCase refreshProfileUseCase,
    GetDriverKycBySidUserUseCase? getKycBySidUserUseCase,
    DriverAuthLocalSession? localSession,
    bool autoRestore = true,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _registerStep1UseCase = registerStep1UseCase,
       _registerStep2UseCase = registerStep2UseCase,
       _logoutUseCase = logoutUseCase,
       _refreshProfileUseCase = refreshProfileUseCase,
       _getKycBySidUserUseCase = getKycBySidUserUseCase,
       _localSession = localSession ?? DriverAuthLocalSession(),
       super(AuthState()) {
    if (autoRestore) {
      _restoreSession();
    }
  }

  final LoginDriverUseCase _loginUseCase;
  final RegisterDriverUseCase _registerUseCase;
  final RegisterDriverStep1UseCase _registerStep1UseCase;
  final RegisterDriverStep2UseCase _registerStep2UseCase;
  final LogoutDriverUseCase _logoutUseCase;
  final RefreshDriverProfileUseCase _refreshProfileUseCase;
  final GetDriverKycBySidUserUseCase? _getKycBySidUserUseCase;
  final DriverAuthLocalSession _localSession;

  Future<void> _restoreSession() async {
    Map<String, dynamic>? userData;
    try {
      userData = await _localSession.restore();
    } catch (_) {
      await _clearSession();
      state = AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    if (userData == null) {
      state = AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    Map<String, dynamic> hydratedUserData;
    try {
      hydratedUserData = await _resolveLatestUserData(userData);
    } catch (_) {
      hydratedUserData = userData;
    }

    state = AuthState(
      status: AuthStatus.authenticated,
      userData: hydratedUserData,
    );
  }

  Future<void> login(String phone, String password) async {
    state = AuthState(status: AuthStatus.loading);

    final result = await _loginUseCase(
      LoginDriverParams(phoneNumber: phone, password: password),
    );

    await result.fold(
      (failure) async => _setError(failure),
      _persistAuthResponse,
    );
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = AuthState(status: AuthStatus.loading);

    final result = await _registerUseCase(RegisterDriverParams(userData: data));

    await result.fold(
      (failure) async => _setError(failure),
      _persistAuthResponse,
    );
  }

  Future<void> registerStep1(String phoneNumber, {String? email}) async {
    state = AuthState(status: AuthStatus.loading);
    final result = await _registerStep1UseCase(
      RegisterDriverStep1Params(phoneNumber: phoneNumber, email: email),
    );
    result.fold(
      (failure) => _setError(failure),
      (_) => state = AuthState(status: AuthStatus.unauthenticated),
    );
    if (state.status == AuthStatus.error) {
      throw Exception(state.errorMessage);
    }
  }

  Future<void> registerStep2(
    String phoneNumber,
    String verificationCode,
  ) async {
    state = AuthState(status: AuthStatus.loading);
    final result = await _registerStep2UseCase(
      RegisterDriverStep2Params(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      ),
    );
    result.fold(
      (failure) => _setError(failure),
      (_) => state = AuthState(status: AuthStatus.unauthenticated),
    );
    if (state.status == AuthStatus.error) {
      throw Exception(state.errorMessage);
    }
  }

  Future<void> logout() async {
    await _clearSession();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateUserData(Map<String, dynamic> newData) async {
    if (state.userData == null) {
      return;
    }

    final normalized = await _localSession.update(state.userData!, newData);
    if (normalized == null) {
      _setError(
        const ServerFailure(
          message: 'Impossible de mettre à jour la session chauffeur.',
        ),
      );
      return;
    }

    state = state.copyWith(userData: normalized);
  }

  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.authenticated || state.userData == null) {
      return;
    }

    final hydratedUserData = await _resolveLatestUserData(state.userData!);
    state = state.copyWith(userData: hydratedUserData);
  }

  Future<void> _persistAuthResponse(Map<String, dynamic> response) async {
    if (response['success'] == false || response['error'] != null) {
      _setError(
        ServerFailure(
          message:
              response['message']?.toString() ??
              response['error']?.toString() ??
              'Authentification chauffeur impossible.',
        ),
      );
      return;
    }

    final token = DriverAuthSessionParser.extractToken(response);
    if (token == null) {
      _setError(
        const ServerFailure(message: 'Aucun token recu du serveur chauffeur.'),
      );
      return;
    }

    final userData = DriverAuthSessionParser.buildUserData(response);
    if (userData == null) {
      _setError(
        const ServerFailure(
          message: 'Impossible d\'identifier le chauffeur connecté.',
        ),
      );
      return;
    }

    if (userData['isDriver'] != true) {
      state = AuthState(status: AuthStatus.wrongRole);
      return;
    }

    final payload = (response['data'] as Map<String, dynamic>?) ?? response;
    final refreshToken = (payload['refresh_token'] ?? payload['refreshToken'])
        ?.toString();

    await _persistSession(
      token: token,
      userData: userData,
      refreshToken: refreshToken,
    );
  }

  Future<void> _persistSession({
    required String token,
    required Map<String, dynamic> userData,
    String? refreshToken,
  }) async {
    await _localSession.persist(token, userData);
    if (refreshToken != null) {
      await LocalStorage.instance.setSecure(
        AppConstants.refreshTokenKey,
        refreshToken,
      );
    }
    final hydratedUserData = await _resolveLatestUserData(userData);
    state = AuthState(
      status: AuthStatus.authenticated,
      userData: hydratedUserData,
    );
    AuthSessionNotifier.instance.reset();
  }

  Future<Map<String, dynamic>> _resolveLatestUserData(
    Map<String, dynamic> userData,
  ) async {
    final result = await _refreshProfileUseCase();
    final profileData = await result.fold((_) async => userData, (
      profile,
    ) async {
      final normalized = await _localSession.mergeProfile(userData, profile);
      return normalized ?? userData;
    });
    return _mergeLatestKycData(profileData);
  }

  Future<Map<String, dynamic>> _mergeLatestKycData(
    Map<String, dynamic> userData,
  ) async {
    final getKycBySidUserUseCase = _getKycBySidUserUseCase;
    if (getKycBySidUserUseCase == null) {
      return userData;
    }

    final sidUserId = _readSidUserId(userData);
    if (sidUserId == null) {
      return userData;
    }

    final result = await getKycBySidUserUseCase(
      GetDriverKycBySidUserParams(sidUserId: sidUserId),
    );
    return result.fold((_) async => userData, (response) async {
      final latestKyc = _extractLatestKyc(response);
      if (latestKyc == null) {
        return userData;
      }

      final normalized = await _localSession.update(userData, {
        'kyc': latestKyc,
        'kycs': [latestKyc],
        'kycStatus': latestKyc['kycStatus'] ?? latestKyc['status'],
      });
      return normalized ?? userData;
    });
  }

  Future<void> _clearSession() async {
    await _logoutUseCase();
  }

  void _setError(Failure failure) {
    state = AuthState(
      status: AuthStatus.error,
      errorMessage: failure.message,
      userData: state.userData,
    );
  }
}

final driverAuthProvider = StateNotifierProvider<DriverAuthNotifier, AuthState>(
  (ref) {
    return DriverAuthNotifier(
      loginUseCase: ref.watch(loginDriverUseCaseProvider),
      registerUseCase: ref.watch(registerDriverUseCaseProvider),
      registerStep1UseCase: ref.watch(registerDriverStep1UseCaseProvider),
      registerStep2UseCase: ref.watch(registerDriverStep2UseCaseProvider),
      logoutUseCase: ref.watch(logoutDriverUseCaseProvider),
      refreshProfileUseCase: ref.watch(refreshDriverProfileUseCaseProvider),
      getKycBySidUserUseCase: ref.watch(getDriverKycBySidUserUseCaseProvider),
    );
  },
);

int? _readSidUserId(Map<String, dynamic> userData) {
  for (final key in const ['driverId', 'userId', 'id']) {
    final value = userData[key];
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

Map<String, dynamic>? _extractLatestKyc(Map<String, dynamic> response) {
  final payload = response['data'];
  if (payload is List) {
    final items = payload
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (items.isEmpty) return null;
    items.sort((a, b) => _kycTimestamp(b).compareTo(_kycTimestamp(a)));
    return items.first;
  }
  if (payload is Map) {
    return Map<String, dynamic>.from(payload);
  }
  if (response['id'] != null || response['status'] != null) {
    return Map<String, dynamic>.from(response);
  }
  return null;
}

DateTime _kycTimestamp(Map<String, dynamic> kyc) {
  for (final key in const ['updateAt', 'updatedAt', 'createAt', 'createdAt']) {
    final value = kyc[key]?.toString();
    if (value == null || value.trim().isEmpty) continue;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
