import 'app_flavor.dart';

/// Liens de téléchargement des applications, joints au partage de l'offre « Invitez vos proches ».
class StoreLinks {
  const StoreLinks._();

  static const String passengerAndroid =
      'https://play.google.com/store/apps/details?id=fraya.taxi.ci';
  static const String driverAndroid =
      'https://play.google.com/store/apps/details?id=fraya.taxi.driver.ci';

  /// Lien Play Store de l'application en cours ; null hors Android ou pour la version de développement.
  static String? shareLink({
    required bool isAndroid,
    required AppFlavor flavor,
  }) {
    if (!isAndroid) return null;
    switch (flavor) {
      case AppFlavor.passenger:
        return passengerAndroid;
      case AppFlavor.driver:
        return driverAndroid;
      case AppFlavor.dev:
        return null;
    }
  }
}
