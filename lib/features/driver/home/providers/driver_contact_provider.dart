import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/passenger_contact_launcher_service.dart';
import '../../../../domain/models/driver_ride.dart';

class DriverContactController {
  const DriverContactController(this._contactLauncherService);

  final PassengerContactLauncherService _contactLauncherService;

  Future<bool> callPassenger(DriverRide ride) {
    return _contactLauncherService.launchPhoneCall(ride.passengerPhone);
  }

  Future<bool> openPassengerWhatsApp(DriverRide ride) {
    return _contactLauncherService.launchWhatsApp(ride.passengerPhone);
  }
}

final driverContactLauncherServiceProvider =
    Provider<PassengerContactLauncherService>(
      (ref) => const PassengerContactLauncherService(),
    );

final driverContactControllerProvider = Provider<DriverContactController>((
  ref,
) {
  final service = ref.watch(driverContactLauncherServiceProvider);
  return DriverContactController(service);
});
