/// Modèle des catégories de course (gammes de véhicule).
///
/// Aligné sur l'API backend :
/// - Gammes : MAGIC, GLADIATEUR, ELITE
/// - Endpoint estimation : POST /rides/maps/estimate (retourne toutes les gammes)
/// - Endpoint demande course : POST /rides/maps/request { requestedRange: "MAGIC" }
///
/// Actuellement hardcodé, prêt pour intégration via :
/// - GET /pricing/configs/range-pricing (tarifs par gamme)
library;

class RideCategory {
  final String id; // Correspond à "range" dans l'API (MAGIC, GLADIATEUR, ELITE)
  final String name;
  final String description;
  final int price; // En FCFA — sera remplacé par le calcul API
  final int? amountReceived;
  final int seats;
  final String? badge;
  final String iconAsset; // Chemin vers l'image SVG du véhicule

  const RideCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.amountReceived,
    required this.seats,
    this.badge,
    required this.iconAsset,
  });

  /// Parse depuis l'API backend (pricing/range-pricing).
  factory RideCategory.fromBackendApi(Map<String, dynamic> json) {
    final range = json['range'] as String? ?? '';
    // Trouver les métadonnées UI locales correspondant à la gamme
    final defaultUI = defaultCategories.firstWhere(
      (cat) => cat.id.toUpperCase() == range.toUpperCase(),
      orElse: () => defaultCategories.first,
    );

    return RideCategory(
      id: range,
      name: defaultUI.name,
      description: defaultUI.description,
      price: defaultUI.price, // Prix de base qui sera écrasé par calculatePrice
      amountReceived: defaultUI.amountReceived,
      seats: defaultUI.seats,
      badge: defaultUI.badge,
      iconAsset: defaultUI.iconAsset,
    );
  }

  RideCategory copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    int? amountReceived,
    int? seats,
    String? badge,
    String? iconAsset,
  }) {
    return RideCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      amountReceived: amountReceived ?? this.amountReceived,
      seats: seats ?? this.seats,
      badge: badge ?? this.badge,
      iconAsset: iconAsset ?? this.iconAsset,
    );
  }

  /// Catégories hardcodées pour le développement.
  /// Seront remplacées par l'appel à GET /pricing/configs/range-pricing.
  static const List<RideCategory> defaultCategories = [
    RideCategory(
      id: 'MAGIC',
      name: 'Magic',
      description: 'Économique et pratique',
      price: 2500,
      seats: 4,
      badge: 'Le moins cher',
      iconAsset: 'assets/images/magic.png',
    ),
    RideCategory(
      id: 'GLADIATEUR',
      name: 'Gladiateur',
      description: 'Confort standard',
      price: 3000,
      seats: 4,
      iconAsset: 'assets/images/gladiateur.png',
    ),
    RideCategory(
      id: 'ELITE',
      name: 'Elite',
      description: 'Véhicules récents, climatisés',
      price: 4500,
      seats: 4,
      badge: 'Confort assuré',
      iconAsset: 'assets/images/elite.png',
    ),
  ];
}
