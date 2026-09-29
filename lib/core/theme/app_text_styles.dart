/// Styles typographiques Fraya Taxi — Design System v3.1.
///
/// Les couleurs ne sont PAS codées ici — elles viennent du ThemeData
/// (light ou dark) via DefaultTextStyle / textTheme.
/// Utiliser .copyWith(color: ...) seulement pour des couleurs sémantiques
/// explicites (erreur, succès, etc.).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  // ──────────────────────────────────────────
  //  HEADINGS — weight: 500 (medium)
  // ──────────────────────────────────────────

  /// 20px / medium — Titres majeurs (écrans principaux).
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// 16px / medium — Titres de sections.
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// 14px / medium — Sous-titres.
  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// 13px / medium — Labels importants.
  static TextStyle get h4 => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // ──────────────────────────────────────────
  //  BODY — weight: 400 (normal)
  // ──────────────────────────────────────────

  /// 16px / normal — Texte standard.
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 14px / normal — Metadata, descriptions courtes.
  static TextStyle get small => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 12px / normal — Labels secondaires, badges.
  static TextStyle get xs => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ──────────────────────────────────────────
  //  BOUTONS — weight: 500 (medium)
  // ──────────────────────────────────────────

  /// 16px / medium — Texte de bouton standard.
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// 14px / medium — Texte de bouton compact.
  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// 18px / medium — Texte de bouton CTA.
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
}
