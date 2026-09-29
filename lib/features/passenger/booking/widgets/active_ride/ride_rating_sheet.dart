import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/models/favorite_place.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/extensions.dart';
import '../../../../../../shared/providers/favorite_places_provider.dart';
import '../../../../../../shared/providers/places_provider.dart';
import '../../../../../../shared/widgets/sheet_handle.dart';
import '../ride_summary/ride_rating_labels.dart';
import '../ride_summary/ride_star_rating_row.dart';
import '../../providers/booking_provider.dart';

class RideRatingSheet extends ConsumerStatefulWidget {
  const RideRatingSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const RideRatingSheet(),
    );
  }

  @override
  ConsumerState<RideRatingSheet> createState() => _RideRatingSheetState();
}

class _RideRatingSheetState extends ConsumerState<RideRatingSheet> {
  int _rating = 0;
  bool _destinationSaved = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
            const SizedBox(height: AppTheme.spacingXl),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Course terminée !',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Comment s\'est passee votre course ?',
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
            const SizedBox(height: AppTheme.spacingMd),
            _SaveDestinationButton(
              saved: _destinationSaved,
              onToggle: _toggleSaveDestination,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating > 0 ? _submit : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
                child: Text(
                  'Envoyer',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextButton(
              onPressed: _skip,
              child: Text(
                'Passer',
                style: AppTextStyles.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSaveDestination() {
    final destination = ref.read(selectedDestinationProvider);
    if (destination == null) return;

    final notifier = ref.read(favoritePlacesProvider.notifier);
    if (_destinationSaved) {
      notifier.remove(
        'fav_${destination.placeId.isNotEmpty ? destination.placeId : destination.address.hashCode}',
      );
    } else {
      notifier.save(FavoritePlace.fromPlaceDetails(destination));
    }
    setState(() => _destinationSaved = !_destinationSaved);
  }

  void _submit() {
    Navigator.pop(context);
    ref.read(bookingFlowProvider.notifier).reset();
  }

  void _skip() {
    Navigator.pop(context);
    ref.read(bookingFlowProvider.notifier).reset();
  }
}

class _SaveDestinationButton extends StatelessWidget {
  const _SaveDestinationButton({required this.saved, required this.onToggle});

  final bool saved;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onToggle,
      icon: Icon(
        saved ? Icons.star_rounded : Icons.star_outline_rounded,
        color: saved ? const Color(0xFFD4A843) : context.colors.textSecondary,
        size: 20,
      ),
      label: Text(
        saved ? 'Destination sauvegardee' : 'Sauvegarder la destination',
        style: AppTextStyles.body.copyWith(
          color: saved ? const Color(0xFFD4A843) : context.colors.textSecondary,
        ),
      ),
    );
  }
}
