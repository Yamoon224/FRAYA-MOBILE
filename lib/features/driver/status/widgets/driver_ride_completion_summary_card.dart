library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_ride.dart';
import '../models/driver_ride_completion_pricing.dart';

class DriverRideCompletionSummaryCard extends StatelessWidget {
  const DriverRideCompletionSummaryCard({super.key, required this.ride});

  final DriverRide ride;

  @override
  Widget build(BuildContext context) {
    final pricing = DriverRideCompletionPricing.fromRide(ride);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.shadowYellowSm,
      ),
      child: Column(
        children: [
          Text('Montant total', style: AppTextStyles.body),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            pricing.finalPrice.toCFA,
            style: AppTextStyles.h1.copyWith(
              fontSize: context.responsiveValue<double>(
                compact: 22,
                phone: 28,
                largePhone: 28,
                tablet: 34,
              ),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (pricing.additionalFee > 0) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Attente: +${pricing.additionalFee.toCFA} (${pricing.lateDurationMin} min)',
              style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricColumn(
                    label: 'Distance',
                    value: ride.estimatedDistanceKm == null
                        ? '-- km'
                        : '${ride.estimatedDistanceKm!.toStringAsFixed(1)} km',
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _MetricColumn(
                    label: 'Durée',
                    value: ride.estimatedDurationMin == null
                        ? '-- min'
                        : '${ride.estimatedDurationMin} min',
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _MetricColumn(
                    label: 'Attente',
                    value: '${pricing.lateDurationMin} min',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      color: context.colors.border,
    );
  }
}
