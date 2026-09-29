import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/address_formatter_service.dart';

void main() {
  group('AddressFormatterService', () {
    const formatter = AddressFormatterService();

    test('normalizes legacy order commune then quartier', () {
      final normalized = formatter.normalize('Cocody, Riviera Palmeraie');
      expect(normalized, 'Riviera Palmeraie, Cocody');
    });

    test('keeps canonical order quartier then commune', () {
      final normalized = formatter.normalize('Riviera Palmeraie, Cocody');
      expect(normalized, 'Riviera Palmeraie, Cocody');
    });

    test('extracts street and commune from verbose Google address', () {
      final normalized = formatter.normalize(
        "Rue 12, Cocody, Abidjan, Côte d'Ivoire",
      );
      expect(normalized, 'Rue 12, Cocody');
    });

    test('returns commune only when there is no quartier', () {
      final normalized = formatter.normalize('Yopougon');
      expect(normalized, 'Yopougon');
    });

    test('canonicalizes Bassam to Grand-Bassam', () {
      expect(formatter.normalize('Bassam'), 'Grand-Bassam');
      expect(formatter.normalize('grand bassam'), 'Grand-Bassam');
      expect(formatter.normalize('Grand-Bassam'), 'Grand-Bassam');
    });

    test(
      'prefers specific commune over Abidjan even when Abidjan comes first',
      () {
        final normalized = formatter.normalize(
          "Rue 12, Abidjan, Cocody, Cote d'Ivoire",
        );
        expect(normalized, 'Rue 12, Cocody');
      },
    );

    test('keeps Abidjan when no specific commune is present', () {
      expect(formatter.normalize('Abidjan'), 'Abidjan');
    });

    test('drops redundant Abidjan after a leading commune', () {
      final normalized = formatter.normalize(
        "Port-Bouët, Abidjan, Côte d'Ivoire",
      );
      expect(normalized, 'Port-Bouët');
    });

    test('keeps quartier then commune, dropping city and country', () {
      final normalized = formatter.normalize(
        "Soleil, Port-Bouët, Abidjan, Côte d'Ivoire",
      );
      expect(normalized, 'Soleil, Port-Bouët');
    });

    test('normalize is idempotent', () {
      final once = formatter.normalize('Cocody, Riviera Palmeraie');
      final twice = formatter.normalize(once);
      expect(twice, once);
    });

    test('keeps searched place then commune from verbose Google address', () {
      final normalized = formatter.normalize(
        "Angre 8eme tranche, Cocody, Abidjan, Cote d'Ivoire",
      );
      expect(normalized, 'Angre 8eme tranche, Cocody');
    });

    test('normalize keeps Grand-Bassam canonical form when called twice', () {
      final once = formatter.normalize('Bassam');
      final twice = formatter.normalize(once);
      expect(once, 'Grand-Bassam');
      expect(twice, 'Grand-Bassam');
    });

    test('prefers POI name when place name is meaningful', () {
      final display = formatter.normalizeForPlace(
        placeName: 'KFC 8eme tranche',
        rawAddress: 'Rue des Jardins, Cocody, Abidjan',
      );
      expect(display, 'KFC 8eme tranche, Cocody');
    });

    test('uses meaningful POI name with explicit commune', () {
      final display = formatter.normalizeForPlace(
        placeName: 'KFC 8eme tranche',
        commune: 'Cocody',
      );
      expect(display, 'KFC 8eme tranche, Cocody');
    });

    test('falls back to street/quartier, commune for non-POI names', () {
      final display = formatter.normalizeForPlace(
        placeName: 'Cocody',
        rawAddress: 'Rue Silue Amadou, Koumassi, Abidjan',
      );
      expect(display, 'Rue Silue Amadou, Koumassi');
    });

    test('reorders compound detail before commune', () {
      final display = formatter.formatLocalityLabel(
        commune: 'Cocody',
        detailCandidates: ['Cocody, Angr\u00e9 7\u00e8me tranche'],
      );
      expect(display, 'Angr\u00e9 7eme tranche, Cocody');
    });

    test('formats route with commune', () {
      final display = formatter.formatLocalityLabel(
        commune: 'Cocody',
        detailCandidates: ['Avenue Aka'],
      );
      expect(display, 'Avenue Aka, Cocody');
    });

    test('canonicalizes Le Plateau commune', () {
      final display = formatter.formatLocalityLabel(
        commune: 'Le Plateau',
        detailCandidates: ['La Cite Administrative'],
      );
      expect(display, 'La Cite Administrative, Plateau');
    });

    test('cleans adr address html fallback', () {
      final display = formatter.formatLocalityLabel(
        commune: 'Cocody',
        adrAddress:
            '<span class="street-address">Rue des Jardins</span>, Abidjan',
      );
      expect(display, 'Rue des Jardins, Cocody');
    });

    test('ignores plus code detail in favor of route', () {
      final display = formatter.formatLocalityLabel(
        commune: 'Cocody',
        detailCandidates: ['8XJV+77P', 'Avenue Aka'],
      );
      expect(display, 'Avenue Aka, Cocody');
    });
  });
}
