import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/core/models/favorite_place.dart';
import 'package:fraya_mobile/shared/providers/favorite_places_provider.dart';
import 'package:fraya_mobile/shared/widgets/fraya_skeleton.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritePlacesListProvider);
    final frequent = ref.watch(frequentDestinationsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Favoris',
          style: AppTextStyles.h3.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoritePlacesListProvider);
          ref.invalidate(frequentDestinationsProvider);
          await ref.read(favoritePlacesListProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            if (frequent.isNotEmpty) ...[
              _SectionTitle('Fréquemment visités'),
              ...frequent.map(
                (fav) => _FavoriteTile(
                  favorite: fav,
                  onTap: () => _navigate(context, ref, fav),
                  showDelete: false,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
            favoritesAsync.when(
              data: (favorites) {
                if (frequent.isEmpty && favorites.isEmpty) {
                  return _EmptyState();
                }
                if (favorites.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Mes favoris'),
                    ...favorites.map(
                      (fav) => _FavoriteTile(
                        favorite: fav,
                        onTap: () => _navigate(context, ref, fav),
                        showDelete: true,
                        onDelete: () => ref
                            .read(favoritePlacesProvider.notifier)
                            .remove(fav.id),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const _FavoritesLoadingState(),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    FavoritePlace fav,
  ) async {
    await ref.read(favoritePlacesProvider.notifier).navigateTo(context, fav);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Text(title, style: AppTextStyles.h4.copyWith(color: context.colors.textSecondary)),
    );
  }
}

class _FavoritesLoadingState extends StatelessWidget {
  const _FavoritesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Chargement des favoris...'),
        for (int i = 0; i < 5; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.greyExtraLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                const FrayaSkeleton(height: 36, width: 36, borderRadius: 18),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 120),
                      SizedBox(height: 8),
                      SkeletonText(width: 180, height: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const FrayaSkeleton(height: 20, width: 20, borderRadius: 10),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.favorite,
    required this.onTap,
    required this.showDelete,
    this.onDelete,
  });

  final FavoritePlace favorite;
  final VoidCallback onTap;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star_rounded,
            color: Color(0xFFD4A843),
            size: 20,
          ),
        ),
        title: Text(
          favorite.name,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          favorite.address,
          style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: showDelete
            ? IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: onDelete,
              )
            : const Icon(Icons.chevron_right, color: AppColors.grey),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.star_outline_rounded,
            size: 64,
            color: context.colors.greyLight,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Aucun favori pour l\'instant',
            style: AppTextStyles.h4.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des destinations depuis la recherche\nou en fin de course.',
            style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
