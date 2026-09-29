import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../shared/widgets/fraya_skeleton.dart';
import 'ride_history_tile.dart';

class RidesList extends StatelessWidget {
  final List<Ride> rides;
  final String emptyMessage;
  final bool isLoading;
  final bool showFooter;
  final VoidCallback? onFooterTap;

  const RidesList({
    super.key,
    required this.rides,
    required this.emptyMessage,
    this.isLoading = false,
    this.showFooter = false,
    this.onFooterTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
        ),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.greyExtraLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FrayaSkeleton(height: 38, width: 38, borderRadius: 19),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonText(width: 150)),
                ],
              ),
              SizedBox(height: 12),
              SkeletonText(width: 220, height: 10),
              SizedBox(height: 8),
              SkeletonText(width: 180, height: 10),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: SkeletonText(width: 90, height: 12)),
                  SizedBox(width: 16),
                  Expanded(child: SkeletonText(width: 90, height: 12)),
                ],
              ),
            ],
          ),
        ),
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingMd),
        itemCount: 5,
      );
    }

    if (rides.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: AppColors.greyLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            showFooter ? 100 : AppTheme.spacingLg,
          ),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return RideHistoryTile(ride: rides[index]);
          },
        ),
        if (showFooter)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onFooterTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Voir toutes les courses',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
