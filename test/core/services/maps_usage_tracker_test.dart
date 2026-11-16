import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/maps_usage_tracker.dart';

void main() {
  group('MapsUsageInterceptor.classify', () {
    test('reconnaît chaque service Google appelé par l\'application', () {
      MapsService? c(String url) =>
          MapsUsageInterceptor.classify(Uri.parse(url));
      expect(
        c('https://maps.googleapis.com/maps/api/place/autocomplete/json'),
        MapsService.placesAutocomplete,
      );
      expect(
        c('https://maps.googleapis.com/maps/api/place/details/json'),
        MapsService.placeDetails,
      );
      expect(
        c('https://maps.googleapis.com/maps/api/place/nearbysearch/json'),
        MapsService.nearbySearch,
      );
      expect(
        c('https://maps.googleapis.com/maps/api/directions/json'),
        MapsService.directions,
      );
      expect(
        c('https://maps.googleapis.com/maps/api/geocode/json'),
        MapsService.geocoding,
      );
      expect(
        c('https://routes.googleapis.com/directions/v2:computeRoutes'),
        MapsService.routes,
      );
      expect(c('https://api.frayataxi.ci/rides'), isNull);
    });
  });

  group('MapsUsageTracker', () {
    test('envoie par lot, sans clé API ni coordonnées', () async {
      final tracker = MapsUsageTracker.instance;
      final bodies = <Map<String, dynamic>>[];
      tracker.sender = (body) async {
        bodies.add(body);
        return Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 202,
        );
      };

      tracker.record(
        MapsService.geocoding,
        success: false,
        durationMs: 40,
        googleStatus: '403',
        errorMessage:
            'failed https://maps.googleapis.com/x?key=AIzaSyABCDEFGHIJKLMNOPQRSTUV&latlng=5.3,-4.0',
      );
      tracker.recordMapLoad();
      await tracker.flush();

      expect(bodies, hasLength(1));
      final events = bodies.single['events'] as List;
      expect(events, hasLength(2));
      expect(events.first['service'], 'GEOCODING');
      expect(events.first['errorMessage'], isNot(contains('AIza')));
      expect(events.last['service'], 'MAP_LOAD');

      await tracker.flush();
      expect(
        bodies,
        hasLength(1),
        reason: 'le tampon est vidé après un envoi réussi',
      );
      tracker.sender = null;
    });
  });
}
