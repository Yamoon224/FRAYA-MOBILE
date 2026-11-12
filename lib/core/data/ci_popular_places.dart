import '../models/places_models.dart';
import '../utils/geo_distance_utils.dart';

/// Base locale des lieux les plus demandés à Abidjan. Elle est interrogée avant
/// Google : un lieu trouvé ici ne coûte aucun appel Places.
///
/// Les coordonnées sont celles du centre du lieu (précision de l'ordre de
/// 100 à 500 m pour les communes) : elles servent à choisir une destination
/// courante, le passager peut toujours préciser avec l'autocomplete Google.
class CiPopularPlace {
  const CiPopularPlace(
    this.id,
    this.name,
    this.locality,
    this.latitude,
    this.longitude, {
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String locality;
  final double latitude;
  final double longitude;
  final List<String> aliases;
}

const ciPopularPlaces = <CiPopularPlace>[
  // Transport (ajouter ici d'autres lieux uniquement avec des coordonnées vérifiées)
  CiPopularPlace(
    'aeroport_fhb',
    'Aéroport Félix Houphouët-Boigny',
    'Port-Bouët, Abidjan',
    5.2614,
    -3.9263,
    aliases: ['aeroport', 'aeroport abidjan', 'fhb', 'port bouet aeroport'],
  ),
  // Communes et quartiers (centre approximatif)
  CiPopularPlace(
    'plateau',
    'Plateau',
    'Abidjan',
    5.3197,
    -4.0167,
    aliases: ['le plateau', 'abidjan plateau'],
  ),
  CiPopularPlace('cocody', 'Cocody', 'Abidjan', 5.3600, -3.9900),
  CiPopularPlace('yopougon', 'Yopougon', 'Abidjan', 5.3364, -4.0870),
  CiPopularPlace('marcory', 'Marcory', 'Abidjan', 5.3030, -3.9860),
  CiPopularPlace('treichville', 'Treichville', 'Abidjan', 5.2950, -4.0050),
  CiPopularPlace('koumassi', 'Koumassi', 'Abidjan', 5.2980, -3.9470),
  CiPopularPlace(
    'port_bouet',
    'Port-Bouët',
    'Abidjan',
    5.2540,
    -3.9260,
    aliases: ['port bouet', 'portbouet'],
  ),
  CiPopularPlace('adjame', 'Adjamé', 'Abidjan', 5.3610, -4.0230),
  CiPopularPlace('abobo', 'Abobo', 'Abidjan', 5.4180, -4.0200),
  CiPopularPlace('attecoube', 'Attécoubé', 'Abidjan', 5.3300, -4.0400),
  CiPopularPlace('bingerville', 'Bingerville', 'Abidjan', 5.3550, -3.8860),
  CiPopularPlace(
    'angre',
    'Angré',
    'Cocody, Abidjan',
    5.4000,
    -3.9800,
    aliases: ['angre 8eme tranche', 'angre chateau'],
  ),
  CiPopularPlace(
    'riviera_golf',
    'Riviera Golf',
    'Cocody, Abidjan',
    5.3500,
    -3.9700,
    aliases: ['riviera', 'riviera 2', 'riviera 3'],
  ),
  CiPopularPlace(
    'deux_plateaux',
    'Deux Plateaux',
    'Cocody, Abidjan',
    5.3750,
    -4.0000,
    aliases: ['2 plateaux', 'deux plateaux vallon', 'vallon'],
  ),
  CiPopularPlace('palmeraie', 'Palmeraie', 'Cocody, Abidjan', 5.3900, -3.9600),
  CiPopularPlace(
    'zone_4',
    'Zone 4',
    'Marcory, Abidjan',
    5.2800,
    -3.9950,
    aliases: ['zone 4 marcory'],
  ),
  CiPopularPlace(
    'bietry',
    'Biétry',
    'Marcory, Abidjan',
    5.2900,
    -3.9800,
    aliases: ['bietry'],
  ),
];

String _fold(String value) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyo';
  final lower = value.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    out.write(i >= 0 ? to[i] : ch);
  }
  return out
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Suggestions de la base locale pour [query] (≥ 3 caractères), triées par
/// pertinence puis par distance si l'origine est connue.
List<PlaceSuggestion> popularPlaceSuggestions(
  String query, {
  double? originLat,
  double? originLng,
  int limit = 5,
}) {
  final q = _fold(query);
  if (q.length < 3) return const [];

  final scored = <MapEntry<int, CiPopularPlace>>[];
  for (final place in ciPopularPlaces) {
    final candidates = [place.name, ...place.aliases].map(_fold);
    var best = -1;
    for (final c in candidates) {
      if (c == q) {
        best = 3;
      } else if (c.startsWith(q)) {
        if (best < 2) best = 2;
      } else if (c.split(' ').any((w) => w.startsWith(q)) || c.contains(q)) {
        if (best < 1) best = 1;
      }
    }
    if (best > 0) scored.add(MapEntry(best, place));
  }
  scored.sort((a, b) => b.key.compareTo(a.key));

  return scored.take(limit).map((entry) {
    final place = entry.value;
    final details = PlaceDetails(
      placeId: 'local_ci_${place.id}',
      name: place.name,
      address: '${place.name}, ${place.locality}',
      latitude: place.latitude,
      longitude: place.longitude,
      localityLabel: place.locality,
    );
    return PlaceSuggestion(
      placeId: details.placeId,
      description: place.locality,
      mainText: place.name,
      secondaryText: place.locality,
      localDetails: details,
      distanceMeters: GeoDistanceUtils.distanceMeters(
        originLat: originLat,
        originLng: originLng,
        destinationLat: place.latitude,
        destinationLng: place.longitude,
      ),
    );
  }).toList();
}
