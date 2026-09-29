import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/exceptions.dart';
import 'passenger_settings_provider.dart';

class PassengerSecurityState {
  const PassengerSecurityState({
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final bool success;

  PassengerSecurityState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? success,
  }) {
    return PassengerSecurityState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

class PassengerSecurityNotifier extends StateNotifier<PassengerSecurityState> {
  PassengerSecurityNotifier(this._ref) : super(const PassengerSecurityState());

  final Ref _ref;

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const PassengerSecurityState(isSubmitting: true);
    try {
      final service = _ref.read(passengerSettingsServiceProvider);
      await service.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = const PassengerSecurityState(success: true);
    } on ServerException catch (error) {
      state = PassengerSecurityState(errorMessage: error.message);
    } on NetworkException catch (error) {
      state = PassengerSecurityState(errorMessage: error.message);
    } catch (error) {
      state = PassengerSecurityState(errorMessage: 'Erreur: $error');
    }
  }

  void clearFeedback() {
    state = const PassengerSecurityState();
  }
}

final passengerSecurityProvider =
    StateNotifierProvider<PassengerSecurityNotifier, PassengerSecurityState>(
      (ref) => PassengerSecurityNotifier(ref),
    );
