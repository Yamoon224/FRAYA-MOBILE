library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/usecases/passenger/rate_ride.dart';
import '../../home/providers/driver_home_provider.dart';
import '../../home/providers/driver_ride_dependencies.dart';
import '../models/driver_ride_completion_pricing.dart';
import '../models/driver_ride_payment_method.dart';

class DriverRideCompletionState {
  const DriverRideCompletionState({
    this.paymentMethod = DriverRidePaymentMethod.cash,
    this.rating = 0,
    this.comment = '',
    this.isSubmitting = false,
    this.isCompleted = false,
    this.errorMessage,
  });

  final DriverRidePaymentMethod paymentMethod;
  final int rating;
  final String comment;
  final bool isSubmitting;
  final bool isCompleted;
  final String? errorMessage;

  DriverRideCompletionState copyWith({
    DriverRidePaymentMethod? paymentMethod,
    int? rating,
    String? comment,
    bool? isSubmitting,
    bool? isCompleted,
    Object? errorMessage = _sentinel,
  }) {
    return DriverRideCompletionState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class DriverRideCompletionController
    extends Notifier<DriverRideCompletionState> {
  @override
  DriverRideCompletionState build() => const DriverRideCompletionState();

  void updatePaymentMethod(DriverRidePaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void updateRating(int rating) {
    final sanitizedRating = rating.clamp(0, 5).toInt();
    final nextRating = state.rating == sanitizedRating ? 0 : sanitizedRating;
    state = state.copyWith(rating: nextRating, errorMessage: null);
  }

  void updateComment(String comment) {
    state = state.copyWith(comment: comment, errorMessage: null);
  }

  Future<bool> submit(DriverRide ride) async {
    if (state.isSubmitting || state.isCompleted) return false;

    final pricing = DriverRideCompletionPricing.fromRide(ride);
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final success = await ref.read(driverHomeProvider.notifier).completeRide(
      rideId: ride.rideId,
      finalDistanceKm: ride.estimatedDistanceKm ?? 0,
      finalDurationMin: ride.estimatedDurationMin ?? 0,
      finalPrice: pricing.finalPrice,
      additionnalFreeSeconds: pricing.paidWaitingSeconds,
    );

    if (success) {
      if (state.rating > 0) await _submitRating(ride.rideId);
      state = state.copyWith(isSubmitting: false, isCompleted: true);
      return true;
    }

    final errorMessage = ref.read(driverHomeProvider).errorMessage;
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: errorMessage ?? 'Impossible de terminer cette course.',
    );
    return false;
  }

  Future<void> _submitRating(String rideId) async {
    final useCase = ref.read(driverRateRideUseCaseProvider);
    final comment = state.comment.trim();
    await useCase(RateRideParams(
      rideId: rideId,
      rating: state.rating,
      comment: comment.isEmpty ? null : comment,
    ));
  }
}

final driverRideCompletionControllerProvider =
    NotifierProvider<DriverRideCompletionController, DriverRideCompletionState>(
      DriverRideCompletionController.new,
      isAutoDispose: true,
    );

const Object _sentinel = Object();
