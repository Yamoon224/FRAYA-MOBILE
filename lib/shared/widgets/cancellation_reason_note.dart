import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// « Annulée par le passager — Prix trop élevé » : auteur et motif d'une course annulée.
class CancellationReasonNote extends StatelessWidget {
  const CancellationReasonNote({
    super.key,
    required this.cancelledBy,
    required this.reason,
    this.viewer,
  });

  /// PASSENGER, DRIVER ou SYSTEM (insensible à la casse) ; inconnu si non renseigné.
  final String? cancelledBy;
  final String? reason;

  /// Qui lit : « vous » à la place de « le passager » / « le chauffeur » quand c'est l'auteur.
  final CancellationViewer? viewer;

  static String authorLabel(String? cancelledBy, {CancellationViewer? viewer}) {
    switch (cancelledBy?.trim().toUpperCase()) {
      case 'PASSENGER':
        return viewer == CancellationViewer.passenger
            ? 'Annulée par vous'
            : 'Annulée par le passager';
      case 'DRIVER':
        return viewer == CancellationViewer.driver
            ? 'Annulée par vous'
            : 'Annulée par le chauffeur';
      case 'SYSTEM':
        return 'Annulée automatiquement';
      default:
        return 'Course annulée';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = reason?.trim();
    return Container(
      key: const Key('cancellation_reason_note'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            authorLabel(cancelledBy, viewer: viewer),
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (text == null || text.isEmpty)
                ? 'Aucun motif indiqué'
                : 'Motif : $text',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

enum CancellationViewer { passenger, driver }
