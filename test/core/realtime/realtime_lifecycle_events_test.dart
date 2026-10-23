import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/realtime/realtime_events.dart';
import 'package:fraya_mobile/core/realtime/socket_io_realtime_service.dart';

void main() {
  test(
    'un événement sans champ status est ignoré tant qu on ne déduit pas son statut',
    () {
      final payload = {'rideId': 5, 'message': 'Votre chauffeur est arrivé'};

      expect(DriverRideStatusRealtimeEvent.tryParse(payload), isNull);
    },
  );

  test(
    'le statut déduit du nom de l événement le rend exploitable par l app passager',
    () {
      final payload = {'rideId': 5, 'message': 'Votre chauffeur est arrivé'};

      for (final entry
          in SocketIoRealtimeService.passengerLifecycleStatuses.entries) {
        final event = DriverRideStatusRealtimeEvent.tryParse(
          payload,
          fallbackStatus: entry.value,
        );
        expect(event, isNotNull, reason: entry.key);
        expect(event!.rideId, '5');
        expect(event.status, entry.value);
      }
      expect(SocketIoRealtimeService.passengerLifecycleStatuses, {
        'ride_started': 'IN_PROGRESS',
        'driver_arrived': 'ARRIVED',
        'ride_completed': 'COMPLETED',
      });
    },
  );

  test('un statut envoyé par le serveur l emporte sur le statut déduit', () {
    final event = DriverRideStatusRealtimeEvent.tryParse({
      'rideId': 5,
      'status': 'ARRIVED',
    }, fallbackStatus: 'IN_PROGRESS');

    expect(event!.status, 'ARRIVED');
  });
}
