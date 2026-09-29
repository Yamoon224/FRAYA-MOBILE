import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../../../core/theme/app_colors.dart';
import '/../../../../core/theme/app_text_styles.dart';
import '/../../../../core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import '/../../../../shared/providers/places_provider.dart';
import '/../../../../shared/providers/saved_places_provider.dart';
import '/../../../../shared/utils/saved_place_icons.dart';
import '/../../../../core/models/places_models.dart';
import '../../providers/destination_search_controller.dart';
import 'place_tile.dart';
import 'suggestion_result_tile.dart';
import 'package:fraya_mobile/shared/widgets/fraya_skeleton.dart';

class DefaultPlacesList extends ConsumerWidget {
  const DefaultPlacesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(destinationSearchControllerProvider);
    final searchType = ref.watch(activeSearchTypeProvider);
    final savedPlacesAsync = ref.watch(savedPlacesNotifierProvider);
    final landmarksAsync = ref.watch(nearbyLandmarksProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      children: [
        const SizedBox(height: AppTheme.spacingLg),

        // ── Adresses enregistrées (Maison, Travail) ──
        const _SectionTitle('Lieux enregistrés'),
        savedPlacesAsync.when(
          data: (places) {
            final home = places
                .where((p) => p.type == SavedAddressType.home)
                .firstOrNull;
            final work = places
                .where((p) => p.type == SavedAddressType.work)
                .firstOrNull;
            final customs = places
                .where((p) => p.type == SavedAddressType.custom)
                .toList();

            if (home == null && work == null && customs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _EmptySavedPlaces(),
              );
            }

            return Column(
              children: [
                if (home != null)
                  PlaceTile(
                    icon: Icons.home_rounded,
                    title: home.label,
                    subtitle: home.place.address,
                    onTap: () => ref
                        .read(destinationSearchControllerProvider.notifier)
                        .handleDirectPlaceSelection(
                          context,
                          home.place,
                          searchType,
                        ),
                  ),
                if (work != null)
                  PlaceTile(
                    icon: Icons.work_rounded,
                    title: work.label,
                    subtitle: work.place.address,
                    onTap: () => ref
                        .read(destinationSearchControllerProvider.notifier)
                        .handleDirectPlaceSelection(
                          context,
                          work.place,
                          searchType,
                        ),
                  ),
                ...customs.map(
                  (c) => PlaceTile(
                    icon: SavedPlaceIcons.iconFromKey(c.iconKey),
                    title: c.label,
                    subtitle: c.place.address,
                    onTap: () => ref
                        .read(destinationSearchControllerProvider.notifier)
                        .handleDirectPlaceSelection(
                          context,
                          c.place,
                          searchType,
                        ),
                  ),
                ),
              ],
            );
          },
          loading: () => const _SkeletonList(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),

        // ── Points de repère dynamiques (Google Places Nearby) ──
        const _SectionTitle('Points de repère populaires'),
        landmarksAsync.when(
          data: (landmarks) {
            // On prend les 5 plus pertinents
            final displayList = landmarks.take(5).toList();

            if (displayList.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Aucun point de repère à proximité'),
              );
            }

            return Column(
              children: displayList
                  .map(
                    (place) => PlaceTile(
                      icon: Icons.location_on_rounded,
                      title: place.name,
                      subtitle: place.vicinity ?? place.address,
                      onTap: () => ref
                          .read(destinationSearchControllerProvider.notifier)
                          .handleDirectPlaceSelection(
                            context,
                            place,
                            searchType,
                          ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const _SkeletonList(),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ],
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      RecentLocationSkeleton(),
      SizedBox(height: 8),
      RecentLocationSkeleton(),
    ],
  );
}

class _EmptySavedPlaces extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aucune adresse enregistrée.',
          style: AppTextStyles.small.copyWith(color: context.colors.textTertiary),
        ),
      ],
    );
  }
}

class SearchResultsList extends ConsumerWidget {
  final AsyncValue<List<PlaceSuggestion>> suggestionsAsync;
  const SearchResultsList({super.key, required this.suggestionsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(destinationSearchControllerProvider);
    final searchType = ref.watch(activeSearchTypeProvider);

    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 160),
              Center(child: Text('Aucun résultat')),
            ],
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: suggestions.length,
          itemBuilder: (context, index) => SuggestionResultTile(
            place: suggestions[index],
            searchType: searchType,
          ),
        );
      },
      loading: () => ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: RecentLocationSkeleton(),
        ),
      ),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      title,
      style: AppTextStyles.h4.copyWith(color: context.colors.textSecondary),
    ),
  );
}
