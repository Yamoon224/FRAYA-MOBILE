library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../models/driver_profile_view_data.dart';

class DriverProfileVehicleCard extends StatelessWidget {
  const DriverProfileVehicleCard({
    super.key,
    required this.vehicle,
    this.onEdit,
  });

  final DriverProfileVehicleViewData vehicle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.colors.surface;
    final innerSurfaceColor = context.colors.surfaceElevated;
    final borderColor = context.colors.greyLight;
    final titleColor = context.colors.textPrimary;
    final subtitleColor = context.colors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: const Icon(Icons.directions_car_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: AppTextStyles.h2.copyWith(color: titleColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.subtitle,
                      style: AppTextStyles.small.copyWith(color: subtitleColor),
                    ),
                  ],
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Modifier',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: titleColor,
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  vehicle.rangeLabel,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: const Color(0xFF4B3907),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: innerSurfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: subtitleColor,
                ),
                const SizedBox(width: 8),
                Text(
                  vehicle.plate,
                  style: AppTextStyles.h3.copyWith(color: titleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
