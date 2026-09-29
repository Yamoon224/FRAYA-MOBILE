import 'dart:math';

import '../../../../domain/models/driver_ride.dart';

class DriverRideCompletionPricing {
  const DriverRideCompletionPricing({
    required this.basePrice,
    required this.paidWaitingSeconds,
  });

  final int basePrice;
  final int paidWaitingSeconds;

  int get lateDurationMin => (paidWaitingSeconds / 60).ceil();
  int get additionalFee => lateDurationMin * 100;
  int get finalPrice => basePrice + additionalFee;

  factory DriverRideCompletionPricing.fromRide(DriverRide ride) {
    final base = (ride.finalPrice ?? ride.estimatedPrice).round();
    final arrivedAt = ride.arrivedAt;
    final startedAt = ride.startedAt;
    if (arrivedAt == null || startedAt == null) {
      return DriverRideCompletionPricing(
        basePrice: base,
        paidWaitingSeconds: 0,
      );
    }
    final elapsedSeconds = startedAt.difference(arrivedAt).inSeconds;
    final paidWaitingSeconds = max(0, elapsedSeconds - 300);
    return DriverRideCompletionPricing(
      basePrice: base,
      paidWaitingSeconds: paidWaitingSeconds,
    );
  }
}
