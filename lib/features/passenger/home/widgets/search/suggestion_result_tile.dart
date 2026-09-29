import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../../../core/theme/app_colors.dart';
import '/../../../../core/theme/app_text_styles.dart';
import '/../../../../core/models/places_models.dart';
import '/../../../../core/models/favorite_place.dart';
import '/../../../../core/utils/measurement_formatter.dart';
import '/../../../../shared/providers/places_provider.dart';
import '/../../../../shared/providers/favorite_places_provider.dart';
import '../../providers/destination_search_controller.dart';

/// Tuile d'une suggestion d'autocomplete. Affiche d'abord le sous-titre dérivé du
/// texte d'autocomplete puis l'enrichit avec la commune exacte (« Angré, Cocody »)
/// dès que les détails du lieu sont résolus. La distance et l'étoile favori sont
/// alignées horizontalement à droite.
class SuggestionResultTile extends ConsumerWidget {
  const SuggestionResultTile({
    super.key,
    required this.place,
    required this.searchType,
  });

  final PlaceSuggestion place;
  final SearchType searchType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritePlacesListProvider).asData?.value ?? [];
    final isFav = favorites.any((f) => f.placeId == place.placeId);

    final detailsAsync = ref.watch(suggestionDetailsProvider(place.placeId));
    final enriched = detailsAsync.asData?.value?.localityLabel;
    final subtitle = (enriched != null && enriched.isNotEmpty)
        ? enriched
        : place.secondaryText;

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      minVerticalPadding: 4,
      horizontalTitleGap: 10,
      leading: const Icon(
        Icons.location_on_outlined,
        color: AppColors.grey,
        size: 20,
      ),
      title: Text(
        place.mainText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.small.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.xs.copyWith(fontSize: 11),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (place.distanceMeters != null) ...[
            Text(
              MeasurementFormatter.formatDistanceMeters(place.distanceMeters!),
              style: AppTextStyles.xs.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFav ? const Color(0xFFD4A843) : AppColors.grey,
              size: 20,
            ),
            onPressed: () {
              final notifier = ref.read(favoritePlacesProvider.notifier);
              if (isFav) {
                final existing = favorites.firstWhere(
                  (f) => f.placeId == place.placeId,
                );
                notifier.remove(existing.id);
              } else {
                notifier.save(FavoritePlace.fromSuggestion(place));
              }
            },
          ),
        ],
      ),
      onTap: () {
        final controller = ref.read(
          destinationSearchControllerProvider.notifier,
        );
        final localDetails = place.localDetails;
        if (localDetails != null) {
          controller.handleDirectPlaceSelection(
            context,
            localDetails,
            searchType,
          );
          return;
        }
        controller.handlePlaceSelection(context, place, searchType);
      },
    );
  }
}
