import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fallback local optimiste : conserve en mémoire les IDs des courses que le
/// passager vient de noter, afin de masquer immédiatement le bouton « Noter »
/// même si `GET /rides/maps` ne renvoie pas encore la note à jour.
class LocallyRatedRides extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markRated(String rideId) {
    if (rideId.isEmpty || state.contains(rideId)) return;
    state = {...state, rideId};
  }

  bool contains(String rideId) => state.contains(rideId);
}

final locallyRatedRideIdsProvider =
    NotifierProvider<LocallyRatedRides, Set<String>>(LocallyRatedRides.new);
