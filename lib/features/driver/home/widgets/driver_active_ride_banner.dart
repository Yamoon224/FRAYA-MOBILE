import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/ride_status.dart';
import '../providers/driver_home_provider.dart';

class DriverActiveRideBanner extends ConsumerWidget {
  const DriverActiveRideBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(
      driverHomeProvider.select((s) => s.activeRide),
    );
    if (ride == null) return const SizedBox.shrink();

    final text = _statusText(ride.status);
    if (text == null) return const SizedBox.shrink();

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
    final dotSize = context.responsiveValue<double>(
      compact: 7,
      phone: 8,
      largePhone: 8,
      tablet: 9,
    );
    final chevronSize = context.responsiveValue<double>(
      compact: 18,
      phone: 20,
      largePhone: 20,
      tablet: 22,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppColors.shadowMd,
        ),
        child: Row(
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.small.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: chevronSize,
            ),
          ],
        ),
      ),
    );
  }

  String? _statusText(RideStatus status) {
    return switch (status) {
      RideStatus.accepted => 'En route vers le passager',
      RideStatus.arrived => 'Passager en attente',
      RideStatus.inProgress => 'Course en cours',
      _ => null,
    };
  }
}
