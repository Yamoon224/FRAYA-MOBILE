library;

import 'driver_ride.dart';

extension DriverRideEarningsX on DriverRide {
  double get driverEarningsAmount {
    return finalPrice ?? estimatedPrice;
  }

  double get driverCommissionAmount => commissionPrice ?? 0;

  double get driverNetEarnings => driverEarningsAmount - driverCommissionAmount;

  int get tripDurationMinutes {
    return estimatedDurationMin ?? 0;
  }
}
