import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/usecases/passenger/create_sos_alert.dart';
import '../../auth/providers/passenger_auth_provider.dart';
import '../../auth/providers/passenger_auth_user_id.dart';
import 'booking_dependencies.dart';

class SosAlertState {
  const SosAlertState({
    this.isSubmitting = false,
    this.errorMessage,
    this.lastSuccessAt,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final DateTime? lastSuccessAt;

  SosAlertState copyWith({
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? lastSuccessAt = _sentinel,
  }) {
    return SosAlertState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      lastSuccessAt: identical(lastSuccessAt, _sentinel)
          ? this.lastSuccessAt
          : lastSuccessAt as DateTime?,
    );
  }
}

class SosAlertController extends Notifier<SosAlertState> {
  @override
  SosAlertState build() => const SosAlertState();

  Future<bool> submit({
    required String rideId,
    double? lat,
    double? lng,
    String? reason,
  }) async {
    if (state.isSubmitting) return false;

    final userId = passengerAuthUserIdFromData(
      ref.read(passengerAuthProvider).userData,
    );
    if (userId == null) {
      state = state.copyWith(errorMessage: 'Utilisateur introuvable.');
      return false;
    }

    final hasGps = lat != null && lng != null;
    final resolvedLat = lat ?? 0;
    final resolvedLng = lng ?? 0;
    final trimmedReason = reason?.trim();
    final resolvedNotes = hasGps
        ? trimmedReason
        : _decorateMissingGpsReason(trimmedReason);

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final useCase = ref.read(createSosAlertUseCaseProvider);
    final result = await useCase(
      CreateSosAlertParams(
        rideId: rideId,
        userId: userId,
        lat: resolvedLat,
        lng: resolvedLng,
        notes: resolvedNotes,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (success) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: null,
          lastSuccessAt: DateTime.now(),
        );
        return success;
      },
    );
  }
}

final sosAlertControllerProvider =
    NotifierProvider<SosAlertController, SosAlertState>(
      SosAlertController.new,
      isAutoDispose: true,
    );

const Object _sentinel = Object();

String _decorateMissingGpsReason(String? reason) {
  final trimmed = reason?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'GPS indisponible';
  }
  return 'GPS indisponible - $trimmed';
}
