/// Palette de couleurs Fraya Taxi — Design System v3.1
///
/// Source : DESIGN_SYSTEM.md — Jaune Taxi comme couleur signature.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ──────────────────────────────────────────
  //  JAUNE TAXI — Couleur signature Fraya
  // ──────────────────────────────────────────
  static const Color primary = Color(0xFFD4A843);
  static const Color primaryLight = Color(0xFFFEE89D);
  static const Color primaryDark = Color.fromARGB(255, 177, 130, 13);

  /// Dégradé pour boutons et éléments premium.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFD4A843),
      Color.fromARGB(255, 245, 226, 166),
      Color.fromARGB(255, 177, 130, 13),
      // Color(0xFFE2B04E),
      // Color(0xFFAA771C)
    ],
  );

  /// Dégradé vertical (onboarding, CTA majeurs).
  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDB913), Color(0xFFE5A500)],
  );

  /// Dégradé pour le statut "Arrivé" (Vert premium).
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  /// Dégradé pour le statut "Approche" (Or premium).
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFD4A843), Color(0xFFFEE89D), Color(0xFFD4A843)],
  );

  // ──────────────────────────────────────────
  //  NOIR — Élégance et contraste
  // ──────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ──────────────────────────────────────────
  //  GRIS — Hiérarchie & Surfaces
  // ──────────────────────────────────────────
  static const Color grey = Color(0xFF6B6B6B);
  static const Color greyLight = Color(0xFFE8E8E8);
  static const Color greyExtraLight = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFE2E8F0);

  // ──────────────────────────────────────────
  //  SURFACES
  // ──────────────────────────────────────────
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfacePressed = Color(0xFFFDFAF3);

  // ──────────────────────────────────────────
  //  FONCTIONNELLES
  // ──────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color successBackground = Color(0xFFDCFCE7);
  static const Color successText = Color(0xFF166534);
  static const Color infoBackground = Color(0xFFDBEAFE);
  static const Color infoText = Color(0xFF1E40AF);

  // ──────────────────────────────────────────
  //  DARK THEME — Surfaces & Textes
  // ──────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2E);
  static const Color darkSurfacePressed = Color(0xFF3A3A3C);
  static const Color darkTextPrimary = Color(0xFFF0F0F0);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextTertiary = Color(0xFF6B6B6B);
  static const Color darkBorder = Color(0xFF3A3A3C);
  static const Color darkGreyLight = Color(0xFF3A3A3C);
  static const Color darkGreyExtraLight = Color(0xFF2C2C2E);
  static const Color darkInfoBackground = Color(0xFF1E3A5F);
  static const Color darkSuccessBackground = Color(0xFF14532D);

  // ──────────────────────────────────────────
  //  OMBRES
  // ──────────────────────────────────────────

  /// Ombre subtile pour les cartes au repos.
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Ombre standard pour les cartes.
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Ombre prononcée pour les modals et bottom sheets.
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Ombre jaune pour les boutons primary au repos.
  static List<BoxShadow> get shadowYellowSm => [
    BoxShadow(
      color: primary.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Ombre jaune hover pour les boutons primary.
  static List<BoxShadow> get shadowYellowMd => [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
