import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/utils/measurement_formatter.dart';
import '../../../../../domain/models/active_ride.dart';
import 'location_section.dart';

/// Section détails de la course (montant, adresses, stats).
class RideDetailsSection extends StatelessWidget {
  const RideDetailsSection({
    super.key,
    required this.ride,
    this.pickupName,
    this.destinationName,
  });

  final ActiveRide ride;
  final String? pickupName;
  final String? destinationName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPriceRow(context),
        const _SectionDivider(),
        _buildLocations(),
        const _SectionDivider(),
        _buildStats(),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Montant total',
          style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
        ),
        Text(
          ride.estimatedPrice.toCFA,
          style: AppTextStyles.h3.copyWith(
            color: const Color(0xFFCBA153),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLocations() {
    return Column(
      children: [
        LocationRow(
          dotColor: AppColors.success,
          label: 'Départ',
          address: ride.pickupAddress ?? pickupName ?? 'Position actuelle',
        ),
        const SizedBox(height: AppTheme.spacingLg),
        LocationRow(
          dotColor: const Color(0xFFCBA153),
          label: 'Arrivée',
          address: ride.destinationAddress ?? destinationName ?? 'Destination',
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StatItem(
          label: 'Distance',
          value: MeasurementFormatter.normalizeDistance(
            ride.estimatedDistance,
            fallback: '0.0 km',
          ),
        ),
        StatItem(
          label: 'Durée',
          value: MeasurementFormatter.normalizeDuration(
            ride.estimatedDuration,
            fallback: '-- min',
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
      child: Divider(color: context.colors.greyLight, thickness: 0.5),
    );
  }
}
