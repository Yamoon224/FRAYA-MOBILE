library;

import 'package:flutter_riverpod/legacy.dart';

import '../../data/repositories/forgot_password_repository.dart';
import '../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../domain/usecases/auth/reset_password_usecase.dart';

enum ForgotPasswordStatus { idle, loading, codeSent, success, error }

class ForgotPasswordState {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.errorMessage,
  });

  final ForgotPasswordStatus status;
  final String? errorMessage;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier({
    required ForgotPasswordUsecase forgotPasswordUsecase,
    required ResetPasswordUsecase resetPasswordUsecase,
  })  : _forgotPasswordUsecase = forgotPasswordUsecase,
        _resetPasswordUsecase = resetPasswordUsecase,
        super(const ForgotPasswordState());

  final ForgotPasswordUsecase _forgotPasswordUsecase;
  final ResetPasswordUsecase _resetPasswordUsecase;

  Future<void> sendResetCode(String identifier) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading);

    final result = await _forgotPasswordUsecase(
      ForgotPasswordParams(identifier: identifier),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(status: ForgotPasswordStatus.codeSent),
    );
  }

  Future<void> resetPassword(
    String verificationCode,
    String newPassword,
  ) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading);

    final result = await _resetPasswordUsecase(
      ResetPasswordParams(
        verificationCode: verificationCode,
        newPassword: newPassword,
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(status: ForgotPasswordStatus.success),
    );
  }
}

final forgotPasswordProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordNotifier, ForgotPasswordState>((ref) {
  final repository = ForgotPasswordRepository();
  return ForgotPasswordNotifier(
    forgotPasswordUsecase: ForgotPasswordUsecase(repository),
    resetPasswordUsecase: ResetPasswordUsecase(repository),
  );
});
