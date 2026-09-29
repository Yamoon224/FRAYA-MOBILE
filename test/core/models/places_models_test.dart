import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';

void main() {
  group('PlaceSuggestion.fromJson', () {
    test('derives subtitle from description (quartier, commune)', () {
      final suggestion = PlaceSuggestion.fromJson({
        'place_id': 'abc',
        'description': "Soleil, Port-Bouët, Abidjan, Côte d'Ivoire",
        'structured_formatting': {
          'main_text': 'Soleil',
          'secondary_text': "Port-Bouët, Abidjan, Côte d'Ivoire",
        },
      });

      expect(suggestion.mainText, 'Soleil');
      expect(suggestion.secondaryText, 'Soleil, Port-Bouët');
    });

    test('parses distance_meters when provided', () {
      final suggestion = PlaceSuggestion.fromJson({
        'place_id': 'abc',
        'description': "Cocody, Abidjan, Côte d'Ivoire",
        'distance_meters': 2400,
      });

      expect(suggestion.distanceMeters, 2400);
    });

    test('leaves distanceMeters null when absent', () {
      final suggestion = PlaceSuggestion.fromJson({
        'place_id': 'abc',
        'description': "Cocody, Abidjan, Côte d'Ivoire",
      });

      expect(suggestion.distanceMeters, isNull);
    });

    test('hides plus code and generic Abidjan subtitle', () {
      final suggestion = PlaceSuggestion.fromJson({
        'place_id': 'technical',
        'description': "8XJV+77P, Abidjan, Cote d'Ivoire",
        'structured_formatting': {
          'main_text': 'Lieu recherché',
          'secondary_text': '8XJV+77P, Abidjan',
        },
      });

      expect(suggestion.secondaryText, isEmpty);
      expect(suggestion.description, 'Lieu recherché');
    });

    test('hides coordinates and generic Abidjan subtitle', () {
      final suggestion = PlaceSuggestion.fromJson({
        'place_id': 'coordinates',
        'description': '5.345678, -4.012345, Abidjan',
        'structured_formatting': {'main_text': 'Position recherchée'},
      });

      expect(suggestion.secondaryText, isEmpty);
    });
  });

  group('PlaceDetails.fromJson localityLabel', () {
    test('recovers commune from administrative_area_level_3', () {
      final details = PlaceDetails.fromJson({
        'place_id': 'xyz',
        'name': 'Angré',
        'geometry': {
          'location': {'lat': 5.4, 'lng': -3.98},
        },
        'address_components': [
          {
            'long_name': 'Angré',
            'types': ['neighborhood'],
          },
          {
            'long_name': 'Cocody',
            'types': ['administrative_area_level_3'],
          },
          {
            'long_name': 'Abidjan',
            'types': ['locality'],
          },
          {
            'long_name': 'Abidjan',
            'types': ['administrative_area_level_2'],
          },
        ],
      });

      expect(details.localityLabel, contains('Cocody'));
      expect(details.localityLabel, isNot(contains('Abidjan')));
    });

    test('builds rich locality label from place name and commune', () {
      final details = PlaceDetails.fromJson({
        'place_id': 'angre_8',
        'name': 'Angre 8eme tranche',
        'formatted_address':
            "Angre 8eme tranche, Cocody, Abidjan, Cote d'Ivoire",
        'geometry': {
          'location': {'lat': 5.39, 'lng': -3.99},
        },
        'address_components': [
          {
            'long_name': 'Angre',
            'types': ['neighborhood'],
          },
          {
            'long_name': 'Cocody',
            'types': ['administrative_area_level_3'],
          },
          {
            'long_name': 'Abidjan',
            'types': ['locality'],
          },
        ],
      });

      expect(details.localityLabel, 'Angre 8eme tranche, Cocody');
      expect(details.address, 'Angre 8eme tranche, Cocody');
    });

    test('does not duplicate commune when place name is a commune', () {
      final details = PlaceDetails.fromJson({
        'place_id': 'cocody',
        'name': 'Cocody',
        'formatted_address': "Cocody, Abidjan, Cote d'Ivoire",
        'geometry': {
          'location': {'lat': 5.35, 'lng': -3.99},
        },
        'address_components': [
          {
            'long_name': 'Cocody',
            'types': ['neighborhood'],
          },
          {
            'long_name': 'Cocody',
            'types': ['administrative_area_level_3'],
          },
          {
            'long_name': 'Abidjan',
            'types': ['locality'],
          },
        ],
      });

      expect(details.localityLabel, 'Cocody');
      expect(details.address, 'Cocody');
    });

    test('formats Neobureau with quartier detail before commune', () {
      final details = PlaceDetails.fromJson({
        'place_id': 'neobureau',
        'name': 'Neobureau',
        'formatted_address':
            "Cocody, Angr\u00e9 7\u00e8me tranche, Abidjan, Cote d'Ivoire",
        'adr_address':
            'Cocody, Angr\u00e9 7\u00e8me tranche, <span class="locality">Abidjan</span>',
        'geometry': {
          'location': {'lat': 5.39, 'lng': -3.99},
        },
        'address_components': [
          {
            'long_name': 'Cocody, Angr\u00e9 7\u00e8me tranche',
            'short_name': '',
            'types': [],
          },
          {
            'long_name': 'Abidjan',
            'types': ['locality', 'political'],
          },
          {
            'long_name': 'Cocody',
            'types': ['political', 'sublocality', 'sublocality_level_1'],
          },
        ],
      });

      expect(details.localityLabel, 'Angr\u00e9 7eme tranche, Cocody');
      expect(details.address, 'Angr\u00e9 7eme tranche, Cocody');
    });

    test(
      'formats route and commune when formatted address starts with plus code',
      () {
        final details = PlaceDetails.fromJson({
          'place_id': 'lycee_classique',
          'name': "Lyc\u00e9e classique d'Abidjan",
          'formatted_address': "8XJV+77P, Av. Aka, Abidjan, Cote d'Ivoire",
          'adr_address':
              '8XJV+77P, <span class="street-address">Av. Aka</span>, <span class="locality">Abidjan</span>',
          'geometry': {
            'location': {'lat': 5.33, 'lng': -3.99},
          },
          'address_components': [
            {
              'long_name': '8XJV+77P',
              'types': ['plus_code'],
            },
            {
              'long_name': 'Avenue Aka',
              'short_name': 'Av. Aka',
              'types': ['route'],
            },
            {
              'long_name': 'Cocody',
              'types': ['political', 'sublocality', 'sublocality_level_1'],
            },
            {
              'long_name': 'Abidjan',
              'types': ['locality', 'political'],
            },
          ],
        });

        expect(details.localityLabel, 'Avenue Aka, Cocody');
        expect(details.address, 'Avenue Aka, Cocody');
      },
    );

    test('formats premise with Plateau commune', () {
      final details = PlaceDetails.fromJson({
        'place_id': 'tour_b',
        'name': 'Tour B',
        'formatted_address': "La Cit\u00e9 Administrative Tour C, Abidjan",
        'adr_address':
            'La Cit\u00e9 Administrative Tour C, <span class="locality">Abidjan</span>',
        'geometry': {
          'location': {'lat': 5.32, 'lng': -4.02},
        },
        'address_components': [
          {
            'long_name': 'La Cit\u00e9 Administrative Tour C',
            'types': ['premise'],
          },
          {
            'long_name': 'Le Plateau',
            'types': ['political', 'sublocality', 'sublocality_level_1'],
          },
          {
            'long_name': 'Abidjan',
            'types': ['locality', 'political'],
          },
        ],
      });

      expect(details.localityLabel, 'La Cit\u00e9 Administrative, Plateau');
      expect(details.address, 'La Cit\u00e9 Administrative, Plateau');
    });
  });
}
