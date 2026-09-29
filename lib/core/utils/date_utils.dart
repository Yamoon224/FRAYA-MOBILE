/// Utilitaires pour la manipulation et le formatage des dates/heures.
library;

class AppDateUtils {
  /// Formate l'heure d'arrivée estimée.
  /// Prend la durée en secondes et retourne une chaîne au format "HH:mm".
  static String formatArrivalTime(int durationSeconds) {
    final arrival = DateTime.now().add(Duration(seconds: durationSeconds));
    final hours = arrival.hour.toString().padLeft(2, '0');
    final minutes = arrival.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Formate un prix en FCFA (ex: 2500 -> 2,500).
  static String formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
