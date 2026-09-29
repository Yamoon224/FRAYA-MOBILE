import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/repositories/special_offer_repository_impl.dart';
import 'package:fraya_mobile/data/sources/local/special_offer_local_data_source.dart';
import 'package:fraya_mobile/domain/models/special_offer.dart';

void main() {
  group('SpecialOfferRepositoryImpl', () {
    test('returns null when the local config is empty', () async {
      final repository = _buildRepository(const []);

      final offer = await repository.getActiveOffer(
        SpecialOfferAudience.passenger,
      );

      expect(offer, isNull);
    });

    test('returns null when the configured offer is inactive', () async {
      final repository = _buildRepository([
        _offerMap(isActive: false, audiences: const ['passenger']),
      ]);

      final offer = await repository.getActiveOffer(
        SpecialOfferAudience.passenger,
      );

      expect(offer, isNull);
    });

    test('returns the active offer for the matching audience', () async {
      final repository = _buildRepository([
        _offerMap(
          id: 'driver-only',
          title: 'Chauffeur',
          audiences: const ['driver'],
        ),
        _offerMap(
          id: 'passenger-offer',
          title: 'Passager',
          audiences: const ['passenger'],
        ),
      ]);

      final offer = await repository.getActiveOffer(
        SpecialOfferAudience.passenger,
      );

      expect(offer?.id, 'passenger-offer');
      expect(offer?.title, 'Passager');
    });

    test('filters offers independently for passenger and driver', () async {
      final repository = _buildRepository([
        _offerMap(id: 'shared', audiences: const ['passenger', 'driver']),
        _offerMap(id: 'driver-only', audiences: const ['driver']),
      ]);

      final passengerOffer = await repository.getActiveOffer(
        SpecialOfferAudience.passenger,
      );
      final driverOffer = await repository.getActiveOffer(
        SpecialOfferAudience.driver,
      );

      expect(passengerOffer?.id, 'shared');
      expect(driverOffer?.id, 'shared');
      expect(
        passengerOffer?.supportsAudience(SpecialOfferAudience.driver),
        true,
      );
    });

    test('counts active offers for the matching audience only', () async {
      final repository = _buildRepository([
        _offerMap(id: 'passenger-active-1', audiences: const ['passenger']),
        _offerMap(
          id: 'shared-active',
          audiences: const ['passenger', 'driver'],
        ),
        _offerMap(
          id: 'passenger-inactive',
          audiences: const ['passenger'],
          isActive: false,
        ),
        _offerMap(id: 'driver-only', audiences: const ['driver']),
      ]);

      final count = await repository.getActiveOfferCount(
        SpecialOfferAudience.passenger,
      );

      expect(count, 2);
    });
  });
}

SpecialOfferRepositoryImpl _buildRepository(List<Map<String, dynamic>> offers) {
  return SpecialOfferRepositoryImpl(
    localDataSource: SpecialOfferLocalDataSource(
      loadConfig: (_) async => jsonEncode(offers),
    ),
  );
}

Map<String, dynamic> _offerMap({
  String id = 'offer-1',
  String title = 'Invitez vos proches',
  String description = 'Partagez Fraya autour de vous.',
  bool isActive = true,
  List<String> audiences = const ['passenger', 'driver'],
  String? shareText,
}) {
  return {
    'id': id,
    'title': title,
    'description': description,
    'isActive': isActive,
    'audiences': audiences,
    ...?shareText == null ? null : {'shareText': shareText},
  };
}
