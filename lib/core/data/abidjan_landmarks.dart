import '../../core/models/places_models.dart';

/// Points de repère notables d'Abidjan.
///
/// Chaque landmark est un [PlaceDetails] avec :
/// - Des coordonnées précises
/// - Un placeId stable (format `landmark_<id>`) utilisé comme référence backend
///   → suffisant pour les endpoints qui utilisent principalement les coordonnées
///   → remplacer par de vrais Google Place IDs si le backend l'exige strictement
class AbidjLandmarks {
  static const List<LandmarkEntry> all = [
    LandmarkEntry(
      place: PlaceDetails(
        placeId: 'landmark_plateau_centre',
        name: 'Plateau Centre',
        address: 'Le Plateau, Abidjan, Côte d\'Ivoire',
        latitude: 5.3245,
        longitude: -4.0201,
      ),
      subtitle: 'Centre des affaires',
      distance: '8 km',
    ),
    LandmarkEntry(
      place: PlaceDetails(
        placeId: 'landmark_aeroport_fbh',
        name: 'Aéroport International FHB',
        address: 'Port-Bouët, Abidjan, Côte d\'Ivoire',
        latitude: 5.2613,
        longitude: -3.9262,
      ),
      subtitle: 'Port-Bouët',
      distance: '12 km',
    ),
    LandmarkEntry(
      place: PlaceDetails(
        placeId: 'landmark_forum_marches',
        name: 'Forum des Marchés',
        address: 'Marcory, Abidjan, Côte d\'Ivoire',
        latitude: 5.3012,
        longitude: -3.9876,
      ),
      subtitle: 'Marcory',
      distance: '9 km',
    ),
    LandmarkEntry(
      place: PlaceDetails(
        placeId: 'landmark_cap_sud',
        name: 'Cap Sud',
        address: 'Centre commercial, Abidjan, Côte d\'Ivoire',
        latitude: 5.2987,
        longitude: -3.9845,
      ),
      subtitle: 'Centre commercial',
      distance: '15 km',
    ),
    LandmarkEntry(
      place: PlaceDetails(
        placeId: 'landmark_universite_fhb',
        name: 'Université Félix Houphouët-Boigny',
        address: 'Cocody, Abidjan, Côte d\'Ivoire',
        latitude: 5.3456,
        longitude: -3.9876,
      ),
      subtitle: 'Cocody',
      distance: '6 km',
    ),
  ];
}

class LandmarkEntry {
  final PlaceDetails place;
  final String subtitle;
  final String distance;

  const LandmarkEntry({
    required this.place,
    required this.subtitle,
    required this.distance,
  });
}
