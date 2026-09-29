library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/passenger_ride_alert_sound_service.dart';

final passengerRideAlertSoundServiceProvider =
    Provider<PassengerRideAlertSoundService>((ref) {
      final service = PassengerRideAlertSoundService();
      ref.onDispose(service.dispose);
      return service;
    });
