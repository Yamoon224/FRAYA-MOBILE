import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/rate_ride.dart';
import 'package:fraya_mobile/core/utils/logger.dart';

class RideSummaryState {
  const RideSummaryState({
    this.rating = 0,
    this.selectedTip,
    this.comment = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.infoMessage,
  });

  final int rating;
  final int? selectedTip;
  final String comment;
  final bool isSubmitting;
  final String? errorMessage;
  final String? infoMessage;

  RideSummaryState copyWith({
    int? rating,
    Object? selectedTip = _sentinel,
    String? comment,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? infoMessage = _sentinel,
  }) {
    return RideSummaryState(
      rating: rating ?? this.rating,
      selectedTip: identical(selectedTip, _sentinel)
          ? this.selectedTip
          : selectedTip as int?,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      infoMessage: identical(infoMessage, _sentinel)
          ? this.infoMessage
          : infoMessage as String?,
    );
  }
}

class RideSummaryController extends Notifier<RideSummaryState> {
  @override
  RideSummaryState build() => const RideSummaryState();

  void updateRating(int rating) {
    state = state.copyWith(
      rating: rating.clamp(1, 5),
      errorMessage: null,
      infoMessage: null,
    );
  }

  void updateTip(int? tip) {
    state = state.copyWith(selectedTip: tip);
  }

  void updateComment(String comment) {
    state = state.copyWith(
      comment: comment,
      errorMessage: null,
      infoMessage: null,
    );
  }

  Future<bool> submitRating(String rideId) async {
    if (state.isSubmitting) return false;
    if (state.rating == 0) return false;

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      infoMessage: null,
    );

    final useCase = ref.read(rateRideUseCaseProvider);
    final result = await useCase(
      RateRideParams(
        rideId: rideId,
        rating: state.rating,
        comment: state.comment.trim().isEmpty ? null : state.comment.trim(),
        tip: state.selectedTip?.toDouble(),
      ),
    );

    return result.fold(
      (failure) {
        _logWarning(
          'rateRide failure: rideId=$rideId result=failure message=${failure.message}',
        );
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
          infoMessage: null,
        );
        return false;
      },
      (outcome) {
        final infoMessage = outcome == RateRideOutcome.alreadySubmitted
            ? 'Votre avis a déjà été pris en compte.'
            : null;
        _logInfo('rateRide completed: rideId=$rideId outcome=$outcome');
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: null,
          infoMessage: infoMessage,
        );
        return true;
      },
    );
  }
}

final rideSummaryControllerProvider =
    NotifierProvider<RideSummaryController, RideSummaryState>(
      RideSummaryController.new,
      isAutoDispose: true,
    );

const Object _sentinel = Object();

void _logInfo(String message) {
  try {
    logger.info(message);
  } catch (_) {}
}

void _logWarning(String message) {
  try {
    logger.warning(message);
  } catch (_) {}
}
