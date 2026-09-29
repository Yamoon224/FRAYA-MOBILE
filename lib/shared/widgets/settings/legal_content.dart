class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

abstract final class LegalContent {
  static List<LegalSection> privacyPolicy() => const [
    LegalSection(
      title: '1. Collecte des données personnelles',
      body:
          'Fraya Taxi collecte les informations nécessaires à la fourniture de ses services de transport. Cela inclut vos nom, prénom, adresse e-mail, numéro de téléphone, ainsi que votre localisation GPS lors de l\'utilisation de l\'application. Pour les chauffeurs, des informations supplémentaires relatives à votre identité et à votre véhicule sont également collectées dans le cadre du processus de vérification (KYC).',
    ),
    LegalSection(
      title: '2. Utilisation des données',
      body:
          'Les données collectées sont utilisées exclusivement pour : la mise en relation entre passagers et chauffeurs, le calcul des trajets et des tarifs, la communication liée aux courses en cours, l\'amélioration de nos services, et la conformité avec les obligations légales et réglementaires en vigueur. Nous ne procédons à aucun traitement automatisé de vos données à des fins de profilage commercial.',
    ),
    LegalSection(
      title: '3. Partage des données',
      body:
          'Vos données personnelles ne sont pas vendues à des tiers. Elles peuvent être partagées avec nos partenaires techniques (hébergement, cartographie, paiement) dans le strict respect du RGPD. En cas d\'obligation légale, Fraya Taxi peut être amené à communiquer certaines informations aux autorités compétentes. Toute sous-traitance est encadrée par des accords de traitement de données conformes à la réglementation.',
    ),
    LegalSection(
      title: '4. Conservation des données',
      body:
          'Vos données sont conservées pendant toute la durée de votre relation avec Fraya Taxi, puis archivées pour une durée de 3 ans à compter de la clôture de votre compte, sauf obligation légale de conservation plus longue. Les données de géolocalisation des trajets sont anonymisées au-delà d\'un délai de 12 mois.',
    ),
    LegalSection(
      title: '5. Sécurité des données',
      body:
          'Fraya Taxi met en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données contre tout accès non autorisé, perte ou divulgation. Les communications sont chiffrées via HTTPS/TLS. L\'accès aux données est restreint aux seuls collaborateurs en ayant besoin dans le cadre de leurs fonctions.',
    ),
    LegalSection(
      title: '6. Vos droits',
      body:
          'Conformément au RGPD, vous disposez d\'un droit d\'accès, de rectification, d\'effacement, de portabilité et d\'opposition au traitement de vos données. Pour exercer ces droits ou pour toute question relative à la protection de vos données, contactez notre Délégué à la Protection des Données à l\'adresse : privacy@frayataxi.com. Vous pouvez également introduire une réclamation auprès de l\'autorité de contrôle compétente.',
    ),
  ];

  static List<LegalSection> termsOfUse() => const [
    LegalSection(
      title: '1. Acceptation des conditions',
      body:
          'En téléchargeant ou en utilisant l\'application Fraya Taxi, vous acceptez pleinement et sans réserve les présentes Conditions Générales d\'Utilisation (CGU). Si vous n\'acceptez pas ces conditions, vous devez cesser immédiatement d\'utiliser l\'application. Fraya Taxi se réserve le droit de modifier ces conditions à tout moment ; les modifications entrent en vigueur dès leur publication dans l\'application.',
    ),
    LegalSection(
      title: '2. Description du service',
      body:
          'Fraya Taxi est une plateforme de mise en relation entre passagers souhaitant effectuer un trajet et chauffeurs professionnels indépendants. L\'application permet la réservation, le suivi en temps réel et le paiement des courses. Fraya Taxi agit en qualité d\'intermédiaire et n\'est pas prestataire de transport. Les chauffeurs exercent leur activité en tant qu\'indépendants titulaires des autorisations réglementaires requises.',
    ),
    LegalSection(
      title: '3. Inscription et compte utilisateur',
      body:
          'L\'utilisation de l\'application nécessite la création d\'un compte personnel. Vous vous engagez à fournir des informations exactes et à jour, à maintenir la confidentialité de vos identifiants, et à notifier immédiatement Fraya Taxi de toute utilisation non autorisée de votre compte. Vous êtes seul responsable des activités réalisées depuis votre compte. L\'inscription est réservée aux personnes majeures ou ayant l\'autorisation de leur représentant légal.',
    ),
    LegalSection(
      title: '4. Utilisation acceptable',
      body:
          'Vous vous engagez à utiliser l\'application de manière licite, loyale et dans le respect des présentes CGU. Il est interdit d\'utiliser le service à des fins frauduleuses, de perturber le fonctionnement de la plateforme, d\'usurper l\'identité d\'un tiers, ou de soumettre des demandes de course fictives. Tout comportement irrespectueux envers les chauffeurs ou les passagers entraînera la suspension immédiate du compte.',
    ),
    LegalSection(
      title: '5. Responsabilités',
      body:
          'Fraya Taxi s\'efforce d\'assurer la disponibilité de la plateforme mais ne peut garantir un service ininterrompu. La responsabilité de Fraya Taxi ne saurait être engagée en cas d\'incident survenant entre un passager et un chauffeur, le contrat de transport étant conclu directement entre eux. Les tarifs affichés sont indicatifs et peuvent varier en fonction du trafic ou des conditions du trajet. Fraya Taxi n\'est pas responsable des pertes ou dommages indirects.',
    ),
    LegalSection(
      title: '6. Résiliation',
      body:
          'Vous pouvez supprimer votre compte à tout moment depuis les paramètres de l\'application. Fraya Taxi se réserve le droit de suspendre ou résilier votre accès sans préavis en cas de violation des présentes CGU, de comportement frauduleux ou de mise en danger d\'autrui. En cas de résiliation, les données sont traitées conformément à notre Politique de Confidentialité. Pour toute question, contactez-nous à : support@frayataxi.com.',
    ),
  ];
}
