library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_ride.dart';

class DriverHomeQueuedRideBanner extends StatelessWidget {
  const DriverHomeQueuedRideBanner({super.key, required this.ride});

  final DriverRide ride;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.responsiveValue<double>(
      compact: 12,
      phone: 16,
      largePhone: 18,
      tablet: 20,
    );
    final verticalPadding = context.responsiveValue<double>(
      compact: 10,
      phone: 12,
      largePhone: 12,
      tablet: 14,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Prochaine course acceptée',
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ride.passengerName} · ${ride.pickupAddress}',
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
