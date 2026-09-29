import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../../data/sources/local_storage.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/auth_session_notifier.dart';
import '../../../../core/services/recent_places_service.dart';
import '../../../../core/error/failures.dart';
import 'passenger_auth_user_id.dart';
import '../repositories/passenger_auth_repository.dart';
import '../../../../domain/usecases/passenger/auth/login_passenger_usecase.dart';
import '../../../../domain/usecases/passenger/auth/register_step1_usecase.dart';
import '../../../../domain/usecases/passenger/auth/register_step2_usecase.dart';
import '../../../../domain/usecases/passenger/auth/register_step3_usecase.dart';
import '../../../../domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import '../../../../shared/providers/device_registration_provider.dart';

class PassengerAuthNotifier extends StateNotifier<AuthState> {
  PassengerAuthNotifier({
    required LoginPassengerUsecase loginUsecase,
    required RegisterStep1Usecase registerStep1Usecase,
    required RegisterStep2Usecase registerStep2Usecase,
    required RegisterStep3Usecase registerStep3Usecase,
    required LogoutPassengerUsecase logoutUsecase,
  }) : _loginUsecase = loginUsecase,
       _registerStep1Usecase = registerStep1Usecase,
       _registerStep2Usecase = registerStep2Usecase,
       _registerStep3Usecase = registerStep3Usecase,
       _logoutUsecase = logoutUsecase,
       super(AuthState()) {
    _checkAuth();
  }

  final LoginPassengerUsecase _loginUsecase;
  final RegisterStep1Usecase _registerStep1Usecase;
  final RegisterStep2Usecase _registerStep2Usecase;
  final RegisterStep3Usecase _registerStep3Usecase;
  final LogoutPassengerUsecase _logoutUsecase;

  static const String _userKey = 'auth_user_data';
  static const String _tokenKey = AppConstants.accessTokenKey;

  Future<void> _checkAuth() async {
    String? userDataStr;
    String? token;
    try {
      userDataStr = await LocalStorage.instance.getSecure(_userKey);
      token = await LocalStorage.instance.getSecure(_tokenKey);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    if (token != null && userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userData: userData,
        );
      } catch (_) {
        await logout();
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String phoneNumber, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _loginUsecase(
      LoginPassengerParams(phoneNumber: phoneNumber, password: password),
    );

    result.fold(
      (failure) => _setError(failure),
      (response) => _handleLoginResponse(response),
    );
  }

  void _handleLoginResponse(Map<String, dynamic> response) {
    if (response['success'] == false || response['error'] != null) {
      _setError(
        ServerFailure(
          message:
              response['message'] ??
              response['error'] ??
              'Identifiants incorrects',
        ),
      );
      return;
    }

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      _setError(
        const ServerFailure(
          message: 'Réponse du serveur invalide (aucune donnée).',
        ),
      );
      return;
    }

    final token = data['access_token'] ?? data['accessToken'];
    if (token == null) {
      _setError(const ServerFailure(message: 'Aucun token reçu du serveur.'));
      return;
    }

    final user = data['user'] as Map<String, dynamic>?;
    if (user?['isDriver'] == true) {
      state = state.copyWith(status: AuthStatus.wrongRole);
      return;
    }

    final refreshToken = (data['refresh_token'] ?? data['refreshToken'])
        ?.toString();
    _persistSession(token: token, refreshToken: refreshToken, userData: user);
  }

  Future<void> registerStep1(String phoneNumber, {String? email}) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _registerStep1Usecase(
      RegisterStep1Params(phoneNumber: phoneNumber, email: email),
    );

    result.fold(
      (failure) => _setError(failure),
      (_) => state = state.copyWith(status: AuthStatus.unauthenticated),
    );

    if (state.status == AuthStatus.error) {
      throw Exception(state.errorMessage);
    }
  }

  Future<void> registerStep2(
    String phoneNumber,
    String verificationCode,
  ) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _registerStep2Usecase(
      RegisterStep2Params(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      ),
    );

    result.fold(
      (failure) => _setError(failure),
      (_) => state = state.copyWith(status: AuthStatus.unauthenticated),
    );

    if (state.status == AuthStatus.error) {
      throw Exception(state.errorMessage);
    }
  }

  Future<void> registerStep3(Map<String, dynamic> data) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _registerStep3Usecase(
      RegisterStep3Params(userData: data),
    );

    await result.fold(
      (failure) async => _setError(failure),
      _handleRegisterStep3Response,
    );
  }

  Future<void> _handleRegisterStep3Response(
    Map<String, dynamic> response,
  ) async {
    if (response['success'] == false || response['error'] != null) {
      _setError(
        ServerFailure(
          message:
              response['message'] ??
              response['error'] ??
              "Erreur d'inscription",
        ),
      );
      return;
    }

    final data = response['data'] as Map<String, dynamic>?;
    final token =
        data?['access_token'] ??
        data?['accessToken'] ??
        response['access_token'];

    if (token == null) {
      _setError(
        const ServerFailure(message: "Aucun token reçu après l'inscription."),
      );
      return;
    }

    await _persistSession(
      token: token,
      userData: data?['user'] ?? response['user'],
    );
  }

  Future<void> register(Map<String, dynamic> data) async {
    await registerStep3(data);
  }

  Future<void> logout() async {
    final userId = passengerAuthUserIdFromData(state.userData)?.toString();
    if (userId != null) {
      await RecentPlacesService(userId).clearAll();
    }
    await LocalStorage.instance.remove(AppConstants.passengerBookingSessionKey);
    await LocalStorage.instance.remove(AppConstants.pendingSearchRideIdKey);
    await LocalStorage.instance.remove(AppConstants.pendingSearchStartedAtKey);
    await LocalStorage.instance.remove(AppConstants.activeRideIdKey);
    await _logoutUsecase();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateUserData(Map<String, dynamic> newData) async {
    if (state.userData == null) return;

    final updatedData = Map<String, dynamic>.from(state.userData!);
    updatedData.addAll(newData);

    await LocalStorage.instance.setSecure(_userKey, jsonEncode(updatedData));
    state = state.copyWith(userData: updatedData);
  }

  void _setError(Failure failure) {
    state = state.copyWith(
      status: AuthStatus.error,
      errorMessage: failure.message,
    );
  }

  Future<void> _persistSession({
    required String token,
    String? refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    await LocalStorage.instance.setSecure(_tokenKey, token);
    if (refreshToken != null) {
      await LocalStorage.instance.setSecure(
        AppConstants.refreshTokenKey,
        refreshToken,
      );
    }
    if (userData != null) {
      await LocalStorage.instance.setSecure(_userKey, jsonEncode(userData));
    }
    state = state.copyWith(
      status: AuthStatus.authenticated,
      userData: userData,
    );
    AuthSessionNotifier.instance.reset();
  }
}

final passengerAuthProvider =
    StateNotifierProvider<PassengerAuthNotifier, AuthState>((ref) {
      final repository = PassengerAuthRepository();
      return PassengerAuthNotifier(
        loginUsecase: LoginPassengerUsecase(repository),
        registerStep1Usecase: RegisterStep1Usecase(repository),
        registerStep2Usecase: RegisterStep2Usecase(repository),
        registerStep3Usecase: RegisterStep3Usecase(repository),
        logoutUsecase: LogoutPassengerUsecase(
          deactivateDeviceRegistrationUseCase: ref.watch(
            deactivateDeviceRegistrationUseCaseProvider,
          ),
        ),
      );
    });
