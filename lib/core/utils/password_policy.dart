library;

import 'package:flutter/services.dart';

/// Règle des mots de passe des passagers et des chauffeurs : un code à 4 chiffres.
///
/// La règle ne s'applique qu'à la création ou au changement du mot de passe. À la connexion, tout mot de
/// passe est accepté (longueur minimale mise à part) : les comptes existants gardent leur mot de passe fort.
class PasswordPolicy {
  const PasswordPolicy._();

  static const int pinLength = 4;

  /// Longueur minimale acceptée à la connexion.
  static const int minLoginLength = pinLength;

  static final RegExp _pin = RegExp(r'^\d{4}$');

  static const String hint = '4 chiffres';

  static const String invalidMessage = 'Le mot de passe doit contenir exactement 4 chiffres';

  static bool isValidNew(String? value) => _pin.hasMatch(value ?? '');

  /// Validateur de champ « nouveau mot de passe ».
  static String? validateNew(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    if (!isValidNew(value)) return invalidMessage;
    return null;
  }

  /// Clavier numérique limité à 4 chiffres pour les champs « nouveau mot de passe ».
  static List<TextInputFormatter> get inputFormatters => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(pinLength),
  ];

  static const TextInputType keyboardType = TextInputType.number;
}
