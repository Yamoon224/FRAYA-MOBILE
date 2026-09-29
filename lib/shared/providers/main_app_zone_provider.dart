library;

import 'package:flutter_riverpod/legacy.dart';

/// True uniquement quand la home driver ou passenger est montée.
/// Permet de restreindre les alertes device (connexion, GPS) aux écrans
/// de l'app principale (home + pages du drawer).
final mainAppZoneProvider = StateProvider<bool>((ref) => false);
