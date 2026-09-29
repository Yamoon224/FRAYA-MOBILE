import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/repositories/booking_repository.dart';
import '../../../../domain/usecases/passenger/rate_ride.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../booking/providers/booking_dependencies.dart';
import '../../booking/widgets/ride_summary/ride_rating_labels.dart';
import '../../booking/widgets/ride_summary/ride_star_rating_row.dart';
import '../details/providers/ride_details_provider.dart';
import '../providers/history_provider.dart';
import '../providers/locally_rated_rides_provider.dart';

/// Feuille de notation réutilisable depuis l'historique et le détail d'une
/// course. Réutilise [RateRideUseCase] et marque la course notée localement
/// (fallback optimiste) tout en invalidant l'historique et le détail.
class HistoryRideRatingSheet extends ConsumerStatefulWidget {
  const HistoryRideRatingSheet({super.key, required this.rideId});

  final String rideId;

  static Future<void> show(BuildContext context, String rideId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryRideRatingSheet(rideId: rideId),
    );
  }

  @override
  ConsumerState<HistoryRideRatingSheet> createState() =>
      _HistoryRideRatingSheetState();
}

class _HistoryRideRatingSheetState
    extends ConsumerState<HistoryRideRatingSheet> {
  int _rating = 0;
  bool _isSubmitting = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final comment = _commentController.text.trim();
    final useCase = ref.read(rateRideUseCaseProvider);
    final result = await useCase(
      RateRideParams(
        rideId: widget.rideId,
        rating: _rating,
        comment: comment.isEmpty ? null : comment,
      ),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSubmitting = false);
        AppSnackBar.showError(context, failure.message);
      },
      (outcome) {
        // Succès ou déjà soumis : on considère la course notée côté UI.
        ref
            .read(locallyRatedRideIdsProvider.notifier)
            .markRated(widget.rideId);
        ref.invalidate(rideHistoryProvider);
        ref.invalidate(rideDetailsProvider(widget.rideId));

        Navigator.of(context).pop();
        final message = outcome == RateRideOutcome.alreadySubmitted
            ? 'Votre avis a déjà été pris en compte.'
            : 'Merci pour votre évaluation !';
        AppSnackBar.showSuccess(context, message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
        boxShadow: AppColors.shadowLg,
      ),
      padding: EdgeInsets.only(
        top: AppTheme.spacingLg,
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingXl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Noter votre chauffeur',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Comment s\'est passée votre course ?',
              style: AppTextStyles.small.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            RideStarRatingRow(
              currentRating: _rating,
              onRatingChanged: (rating) => setState(() => _rating = rating),
              activeColor: const Color(0xFFFFC107),
              inactiveColor: context.colors.greyLight,
              activeIcon: Icons.star_rounded,
              inactiveIcon: Icons.star_outline_rounded,
              iconSize: 44,
              compactIconSize: 36,
              tapTargetSize: 46,
              compactTapTargetSize: 40,
              allowClear: false,
            ),
            if (_rating > 0) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                rideRatingLabels[_rating - 1],
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: AppTheme.spacingLg),
            TextField(
              controller: _commentController,
              maxLines: 3,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                hintText: 'Laissez un commentaire... (optionnel)',
                hintStyle: AppTextStyles.small.copyWith(
                  color: context.colors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide(color: context.colors.greyLight),
                ),
                contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_rating > 0 && !_isSubmitting) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Envoyer',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
