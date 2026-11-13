import 'app_flavor.dart';

/// Liens de téléchargement des applications, joints au partage de l'offre « Invitez vos proches ».
class StoreLinks {
  const StoreLinks._();

  static const String passengerAndroid =
      'https://play.google.com/store/apps/details?id=fraya.taxi.ci';
  static const String driverAndroid =
      'https://play.google.com/store/apps/details?id=fraya.taxi.driver.ci';

  static const String passengerIos =
      'https://apps.apple.com/ci/app/fraya-taxi/id6825035633';
  static const String driverIos =
      'https://apps.apple.com/ci/app/fraya-taxi-driver/id6825035443';

  /// Lien de la boutique (Play Store ou App Store) de l'application en cours ;
  /// null hors Android/iOS ou pour la version de développement.
  static String? shareLink({
    required bool isAndroid,
    bool isIos = false,
    required AppFlavor flavor,
  }) {
    if (!isAndroid && !isIos) return null;
    switch (flavor) {
      case AppFlavor.passenger:
        return isAndroid ? passengerAndroid : passengerIos;
      case AppFlavor.driver:
        return isAndroid ? driverAndroid : driverIos;
      case AppFlavor.dev:
        return null;
    }
  }
}
