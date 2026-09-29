/// Extensions utilitaires Dart / Flutter.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_snack_bar.dart';
import 'measurement_formatter.dart';

// ──────────────────────────────────────────
//  BuildContext
// ──────────────────────────────────────────

extension ContextExtensions on BuildContext {
  /// Accès rapide au thème.
  ThemeData get theme => Theme.of(this);

  /// Accès rapide au ColorScheme.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Accès rapide au TextTheme.
  TextTheme get textTheme => theme.textTheme;

  /// Taille de l'écran.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Largeur de l'écran.
  double get screenWidth => screenSize.width;

  /// Hauteur de l'écran.
  double get screenHeight => screenSize.height;

  /// Padding du système (safe area).
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Couleurs adaptées au thème courant.
  ThemeColors get colors => ThemeColors(Theme.of(this).brightness == Brightness.dark);

  /// Affiche un SnackBar.
  void showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      AppSnackBar.showError(this, message);
      return;
    }
    AppSnackBar.showInfo(this, message);
  }
}

// ──────────────────────────────────────────
//  ThemeColors — couleurs adaptées au thème
// ──────────────────────────────────────────

class ThemeColors {
  const ThemeColors(this.isDark);

  final bool isDark;

  Color get surface =>
      isDark ? AppColors.darkSurface : AppColors.surface;
  Color get surfaceElevated =>
      isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated;
  Color get surfacePressed =>
      isDark ? AppColors.darkSurfacePressed : AppColors.surfacePressed;
  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.background;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textTertiary =>
      isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
  Color get border =>
      isDark ? AppColors.darkBorder : AppColors.border;
  Color get greyLight =>
      isDark ? AppColors.darkGreyLight : AppColors.greyLight;
  Color get greyExtraLight =>
      isDark ? AppColors.darkGreyExtraLight : AppColors.greyExtraLight;
  Color get infoBackground =>
      isDark ? AppColors.darkInfoBackground : AppColors.infoBackground;
  Color get successBackground =>
      isDark ? AppColors.darkSuccessBackground : AppColors.successBackground;
}

// ──────────────────────────────────────────
//  String
// ──────────────────────────────────────────

extension StringExtensions on String {
  /// Capitalize la première lettre.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Vérifie si c'est un email valide.
  bool get isValidEmail => RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(this);

  /// Vérifie si c'est un numéro de téléphone ivoirien.
  bool get isValidPhoneCI =>
      RegExp(r'^\+?225\s?[0-9]{10}$').hasMatch(replaceAll(' ', ''));
}

// ──────────────────────────────────────────
//  DateTime
// ──────────────────────────────────────────

extension DateTimeExtensions on DateTime {
  /// Format court : 28 avr. 2026
  String get shortDate => DateFormat('d MMM yyyy', 'fr_FR').format(this);

  /// Format avec heure : 28 avr. 2026 à 14h30
  String get withTime =>
      DateFormat("d MMM yyyy 'à' HH'h'mm", 'fr_FR').format(this);

  /// Heure seule : 14h30
  String get timeOnly => DateFormat("HH'h'mm", 'fr_FR').format(this);

  /// Temps écoulé depuis (ex: "il y a 5 min").
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inDays > 0) return 'il y a ${diff.inDays} j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours} h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes} min';
    return "à l'instant";
  }
}

// ──────────────────────────────────────────
//  num (prix FCFA)
// ──────────────────────────────────────────

extension NumExtensions on num {
  /// Formatte en prix FCFA : 3 000 FCFA
  String get toCFA => MeasurementFormatter.formatCurrency(this);
}
