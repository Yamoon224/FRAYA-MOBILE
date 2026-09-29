import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../../core/utils/constants.dart';
import '../../../../data/sources/local_storage.dart';
import 'booking_dependencies.dart';
import '../../../../domain/models/active_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../domain/usecases/passenger/get_active_ride.dart';
import 'booking_flow_utils.dart';
import '../../auth/providers/passenger_auth_provider.dart';
import 'active_ride_provider.dart';

final activeRideCheckProvider = FutureProvider<ActiveRide?>((ref) async {
  final auth = ref.watch(passengerAuthProvider);

  if (auth.status != AuthStatus.authenticated || auth.userData == null) {
    return null;
  }

  final userId = BookingFlowUtils.parseUserId(auth.userData!);
  if (userId == null) return null;

  // Hint LocalStorage : accélère la restauration en ciblant la course exacte.
  final savedRideId = LocalStorage.instance.getString(
    AppConstants.activeRideIdKey,
  );

  final getActiveRide = ref.read(getActiveRideUseCaseProvider);

  try {
    final result = await getActiveRide(
      GetActiveRideParams(userId: userId, rideId: savedRideId),
    );

    final activeRide = result.fold((failure) => null, (activeRide) {
      return activeRide;
    });
    if (activeRide == null) {
      return null;
    }
    if (activeRide.rideId.isEmpty) {
      return null;
    }
    return switch (activeRide.status) {
      RideStatus.accepted ||
      RideStatus.arrived ||
      RideStatus.inProgress => activeRide,
      RideStatus.completed => _completeRide(ref, activeRide),
      RideStatus.cancelled => _clearTerminalRide(),
      RideStatus.pending => null,
    };
  } catch (e) {
    return null;
  }
});

ActiveRide? _completeRide(Ref ref, ActiveRide ride) {
  ref.read(completedRideControllerProvider.notifier).initialize(ride);
  _removeSavedActiveRideId();
  return null;
}

ActiveRide? _clearTerminalRide() {
  _removeSavedActiveRideId();
  return null;
}

void _removeSavedActiveRideId() {
  if (!LocalStorage.instance.isInitialized) return;
  unawaited(LocalStorage.instance.remove(AppConstants.activeRideIdKey));
}
