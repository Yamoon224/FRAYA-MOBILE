import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/exceptions.dart';
import 'driver_settings_provider.dart';

class DriverSecurityState {
  const DriverSecurityState({
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final bool success;

  DriverSecurityState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? success,
  }) {
    return DriverSecurityState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

class DriverSecurityNotifier extends StateNotifier<DriverSecurityState> {
  DriverSecurityNotifier(this._ref) : super(const DriverSecurityState());

  final Ref _ref;

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const DriverSecurityState(isSubmitting: true);
    try {
      final service = _ref.read(driverSettingsServiceProvider);
      await service.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = const DriverSecurityState(success: true);
    } on ServerException catch (error) {
      state = DriverSecurityState(errorMessage: error.message);
    } on NetworkException catch (error) {
      state = DriverSecurityState(errorMessage: error.message);
    } catch (error) {
      state = DriverSecurityState(errorMessage: 'Erreur: $error');
    }
  }

  void clearFeedback() {
    state = const DriverSecurityState();
  }
}

final driverSecurityProvider =
    StateNotifierProvider<DriverSecurityNotifier, DriverSecurityState>(
      (ref) => DriverSecurityNotifier(ref),
    );
