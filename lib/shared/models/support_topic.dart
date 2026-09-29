library;

enum SupportAudience { passenger, driver }

extension SupportAudienceX on SupportAudience {
  String get appLabel => switch (this) {
    SupportAudience.passenger => 'Fraya Taxi',
    SupportAudience.driver => 'Fraya Chauffeur',
  };

  String get roleLabel => switch (this) {
    SupportAudience.passenger => 'Passager',
    SupportAudience.driver => 'Chauffeur',
  };
}

class SupportTopic {
  const SupportTopic({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

abstract final class SupportTopics {
  static List<SupportTopic> forAudience(SupportAudience audience) {
    return switch (audience) {
      SupportAudience.passenger => passenger,
      SupportAudience.driver => driver,
    };
  }

  static const List<SupportTopic> passenger = [
    SupportTopic(
      id: 'ride',
      label: 'Une course',
      description: 'Besoin d\'aide concernant une course ou son deroulement.',
    ),
    SupportTopic(
      id: 'ride-payment',
      label: 'Paiement de course non valide',
      description:
          'Le paiement d\'une course n\'a pas ete valide correctement.',
    ),
  ];

  static const List<SupportTopic> driver = [
    SupportTopic(
      id: 'ride',
      label: 'Une course',
      description: 'Besoin d\'aide concernant une course ou un client.',
    ),
    SupportTopic(
      id: 'wallet-reload',
      label: 'Rechargement wallet',
      description: 'Probleme de rechargement ou solde non mis a jour.',
    ),
    SupportTopic(
      id: 'package-subscription',
      label: 'Souscription a un package',
      description: 'Le package n\'a pas ete active ou facture correctement.',
    ),
    SupportTopic(
      id: 'ride-payment',
      label: 'Paiement de course non valide',
      description: 'Le paiement d\'une course reste en attente ou incoherent.',
    ),
    SupportTopic(
      id: 'double-commission',
      label: 'Commission facturee deux fois',
      description: 'Une commission semble avoir ete debitee en double.',
    ),
    SupportTopic(
      id: 'kyc-rejected',
      label: 'KYC invalide',
      description: 'Le dossier KYC a ete invalide et vous voulez de l\'aide.',
    ),
  ];
}
