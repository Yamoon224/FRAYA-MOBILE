import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class FrayaSkeleton extends StatelessWidget {
  const FrayaSkeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.margin,
  });

  final double? height;
  final double? width;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.greyLight.withValues(alpha: 0.5);
    final highlightColor = isDark
        ? AppColors.darkSurfacePressed
        : Colors.white.withValues(alpha: 0.8);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppTheme.radiusMd,
          ),
        ),
      ),
    );
  }
}

/// Squelette pré-configuré pour un texte (ligne).
class SkeletonText extends StatelessWidget {
  const SkeletonText({super.key, this.width, this.height = 14, this.margin});

  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return FrayaSkeleton(
      width: width,
      height: height,
      margin: margin,
      borderRadius: height / 2,
    );
  }
}

/// Squelette de la page d'accueil (utilisé pendant le splash/chargement).
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          // Skeleton pour la map
          const FrayaSkeleton(
            height: double.infinity,
            width: double.infinity,
            borderRadius: 0,
          ),

          // Skeleton pour le header (Address pill)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 80,
            right: AppTheme.spacingMd,
            child: const FrayaSkeleton(height: 48, borderRadius: 100),
          ),

          // Skeleton pour le menu
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: AppTheme.spacingMd,
            child: const FrayaSkeleton(
              height: 48,
              width: 48,
              borderRadius: 100,
            ),
          ),

          // Skeleton pour le bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: FrayaSkeleton(height: 4, width: 40, borderRadius: 2),
                  ),
                  const SizedBox(height: 20),
                  const SkeletonText(width: 200, height: 24),
                  const SizedBox(height: 20),
                  // List of search skeletons
                  for (int i = 0; i < 3; i++) ...[
                    const RecentLocationSkeleton(),
                    if (i < 2) const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Squelette pour une ligne de lieu récent.
class RecentLocationSkeleton extends StatelessWidget {
  const RecentLocationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FrayaSkeleton(height: 40, width: 40, borderRadius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonText(width: MediaQuery.of(context).size.width * 0.5),
              const SizedBox(height: 6),
              SkeletonText(
                width: MediaQuery.of(context).size.width * 0.3,
                height: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Squelette pour une carte de catégorie de véhicule.
class RideCategorySkeleton extends StatelessWidget {
  const RideCategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const FrayaSkeleton(height: 40, width: 64, borderRadius: 8),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 100, height: 18),
                const SizedBox(height: 6),
                const SkeletonText(width: 150, height: 12),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonText(width: 60, height: 20),
              SizedBox(height: 4),
              SkeletonText(width: 30, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
