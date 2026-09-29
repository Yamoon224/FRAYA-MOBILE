import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import '../../providers/history_provider.dart';

part 'ride_details_provider.g.dart';

@riverpod
Future<Ride> rideDetails(Ref ref, String rideId) async {
  final history = await ref.watch(rideHistoryProvider.future);
  for (final ride in history) {
    if (ride.id == rideId) return ride;
  }
  throw StateError('Aucun detail disponible pour cette course.');
}
