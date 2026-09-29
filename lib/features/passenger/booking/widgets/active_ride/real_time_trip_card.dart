import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../providers/active_ride_live_metrics_provider.dart';

class RealTimeTripCard extends StatelessWidget {
  const RealTimeTripCard({
    super.key,
    required this.remainingTime,
    required this.remainingDistance,
    required this.source,
  });

  final String remainingTime;
  final String remainingDistance;
  final ActiveRideLiveMetricsSource source;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = EdgeInsets.all(
      context.responsiveValue<double>(
        compact: 12,
        phone: AppTheme.spacingMd,
        largePhone: AppTheme.spacingMd,
        tablet: AppTheme.spacingLg,
      ),
    );
    final spacing = context.responsiveValue<double>(
      compact: 12,
      phone: AppTheme.spacingMd,
      largePhone: AppTheme.spacingMd,
      tablet: AppTheme.spacingLg,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackStats = constraints.maxWidth < 360;

        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFF90CAF9),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.navigation_outlined,
                          color: AppColors.primary,
                          size: context.responsiveValue<double>(
                            compact: 18,
                            phone: 20,
                            largePhone: 20,
                            tablet: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Trajet en temps reel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textBody.copyWith(
                              color: isDark
                                  ? const Color(0xFF90CAF9)
                                  : const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _sourceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.xs.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: spacing),
              if (stackStats)
                Column(
                  children: [
                    _TripStatItem(
                      icon: Icons.access_time,
                      label: 'Temps restant',
                      value: remainingTime,
                    ),
                    SizedBox(height: spacing),
                    _TripStatItem(
                      icon: Icons.location_on_outlined,
                      label: 'Distance restante',
                      value: remainingDistance,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _TripStatItem(
                        icon: Icons.access_time,
                        label: 'Temps restant',
                        value: remainingTime,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _TripStatItem(
                        icon: Icons.location_on_outlined,
                        label: 'Distance restante',
                        value: remainingDistance,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  String get _sourceLabel {
    return switch (source) {
      ActiveRideLiveMetricsSource.directions => 'Source: trafic live',
      ActiveRideLiveMetricsSource.approximate => 'Source: estimation',
      ActiveRideLiveMetricsSource.backend => 'Source: estimation backend',
    };
  }
}

class _TripStatItem extends StatelessWidget {
  const _TripStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = EdgeInsets.symmetric(
      horizontal: context.responsiveValue<double>(
        compact: 14,
        phone: AppTheme.spacingMd,
        largePhone: AppTheme.spacingMd,
        tablet: AppTheme.spacingLg,
      ),
      vertical: context.responsiveValue<double>(
        compact: 14,
        phone: AppTheme.spacingLg,
        largePhone: AppTheme.spacingLg,
        tablet: AppTheme.spacingXl,
      ),
    );

    return Container(
      constraints: BoxConstraints(
        minHeight: context.responsiveValue<double>(
          compact: 104,
          phone: 112,
          largePhone: 116,
          tablet: 120,
        ),
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.xs.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textBody.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
