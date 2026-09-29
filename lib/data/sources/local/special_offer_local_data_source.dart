library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/models/special_offer.dart';

typedef SpecialOfferConfigLoader = Future<String> Function(String assetPath);

class SpecialOfferLocalDataSource {
  SpecialOfferLocalDataSource({
    SpecialOfferConfigLoader? loadConfig,
    this.assetPath = 'assets/config/special_offers.json',
  }) : _loadConfig = loadConfig ?? rootBundle.loadString;

  final SpecialOfferConfigLoader _loadConfig;
  final String assetPath;

  Future<List<SpecialOffer>> getOffers() async {
    final rawConfig = await _loadConfig(assetPath);
    final decoded = jsonDecode(rawConfig);
    if (decoded is! List) return const <SpecialOffer>[];

    return decoded
        .whereType<Map>()
        .map((entry) => SpecialOffer.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }
}
