import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/passenger_contact_launcher_service.dart';
import '../../../../../domain/models/active_ride.dart';

class PassengerContactController {
  const PassengerContactController(this._contactLauncherService);

  final PassengerContactLauncherService _contactLauncherService;

  Future<bool> callDriver(ActiveRide ride) {
    return _contactLauncherService.launchPhoneCall(ride.driverPhone);
  }

  Future<bool> openDriverWhatsApp(ActiveRide ride) {
    return _contactLauncherService.launchWhatsApp(ride.driverPhone);
  }
}

final passengerContactLauncherServiceProvider =
    Provider<PassengerContactLauncherService>(
      (ref) => const PassengerContactLauncherService(),
    );

final passengerContactControllerProvider = Provider<PassengerContactController>(
  (ref) {
    final service = ref.watch(passengerContactLauncherServiceProvider);
    return PassengerContactController(service);
  },
);
