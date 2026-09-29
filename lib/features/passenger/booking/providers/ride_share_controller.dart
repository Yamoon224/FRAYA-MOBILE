import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/services/ride_tracking_share_service.dart';
import '../../../../../domain/usecases/passenger/create_ride_share_link.dart';
import '../../../../../domain/usecases/passenger/share_ride_tracking_message.dart';
import 'active_ride_provider.dart';
import 'booking_dependencies.dart';

enum RideShareFeedbackType { success, info, error }

class RideShareFeedback {
  const RideShareFeedback({required this.message, required this.type});

  final String message;
  final RideShareFeedbackType type;
}

class RideShareState {
  const RideShareState({
    this.isSubmitting = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String? errorMessage;

  RideShareState copyWith({
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
  }) {
    return RideShareState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class RideShareController extends Notifier<RideShareState> {
  @override
  RideShareState build() => const RideShareState();

  Future<RideShareFeedback?> shareActiveRide() async {
    if (state.isSubmitting) return null;

    final rideId = ref.read(activeRideControllerProvider)?.rideId.trim() ?? '';
    if (rideId.isEmpty) {
      return _setError('Impossible de partager la course pour le moment.');
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final linkResult = await ref.read(createRideShareLinkUseCaseProvider).call(
          CreateRideShareLinkParams(rideId: rideId),
        );
    final link = linkResult.fold((_) => null, (value) => value);
    if (link == null) {
      return _finish(_setError('Impossible de generer le lien de suivi.'));
    }

    final shareResult = await ref
        .read(shareRideTrackingMessageUseCaseProvider)
        .call(ShareRideTrackingMessageParams(url: link.url));

    return _finish(
      shareResult.fold(
        (failure) => _setError(_shareErrorMessage(failure)),
        (status) => _feedbackForStatus(status),
      ),
    );
  }

  RideShareFeedback _feedbackForStatus(RideTrackingShareStatus status) {
    switch (status) {
      case RideTrackingShareStatus.success:
      case RideTrackingShareStatus.unavailable:
        return const RideShareFeedback(
          message: 'Partage reussi.',
          type: RideShareFeedbackType.success,
        );
      case RideTrackingShareStatus.dismissed:
        return const RideShareFeedback(
          message: 'Partage annule.',
          type: RideShareFeedbackType.info,
        );
    }
  }

  RideShareFeedback _setError(String message) {
    state = state.copyWith(errorMessage: message);
    return RideShareFeedback(
      message: message,
      type: RideShareFeedbackType.error,
    );
  }

  RideShareFeedback _finish(RideShareFeedback feedback) {
    state = state.copyWith(isSubmitting: false);
    return feedback;
  }

  String _shareErrorMessage(Failure failure) {
    final message = failure.message.trim();
    if (message.isEmpty) {
      return 'Impossible de partager la course pour le moment.';
    }
    return message;
  }
}

final rideShareControllerProvider =
    NotifierProvider<RideShareController, RideShareState>(
      RideShareController.new,
    );

const Object _sentinel = Object();
