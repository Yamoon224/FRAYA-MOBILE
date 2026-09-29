import 'package:flutter/material.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/shared/widgets/sheet_handle.dart';

class RideReceiptSheet extends StatelessWidget {
  const RideReceiptSheet({super.key, required this.ride});

  final Ride ride;

  static void show(BuildContext context, Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RideReceiptSheet(ride: ride),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppTheme.radius2xl)),
        boxShadow: AppColors.shadowLg,
      ),
      padding: EdgeInsets.only(
        top: AppTheme.spacingLg,
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingXl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reçu de course',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  ride.date.shortDate,
                  style: AppTextStyles.small.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              'Réf. #${ride.id.length > 8 ? ride.id.substring(0, 8).toUpperCase() : ride.id.toUpperCase()}',
              style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _Divider(),
            const SizedBox(height: AppTheme.spacingLg),
            _ReceiptRow(
              icon: Icons.radio_button_checked,
              iconColor: AppColors.success,
              label: 'Départ',
              value: ride.departureAddress,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _ReceiptRow(
              icon: Icons.location_on,
              iconColor: AppColors.error,
              label: 'Arrivée',
              value: ride.arrivalAddress,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _Divider(),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              children: [
                if (ride.duration != null)
                  Expanded(
                    child: _StatItem(
                      label: 'Durée',
                      value: ride.duration!,
                    ),
                  ),
                if (ride.distance != null)
                  Expanded(
                    child: _StatItem(
                      label: 'Distance',
                      value: ride.distance!,
                    ),
                  ),
                Expanded(
                  child: _StatItem(
                    label: 'Catégorie',
                    value: ride.vehicleRange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _Divider(),
            const SizedBox(height: AppTheme.spacingLg),
            if (ride.driverName != null)
              _ReceiptRow(
                icon: Icons.person_outline,
                iconColor: context.colors.textSecondary,
                label: 'Chauffeur',
                value: ride.driverName!,
              ),
            if (ride.vehicleModel != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              _ReceiptRow(
                icon: Icons.directions_car_outlined,
                iconColor: context.colors.textSecondary,
                label: 'Véhicule',
                value: '${ride.vehicleModel}'
                    '${ride.licensePlate != null ? ' · ${ride.licensePlate}' : ''}',
              ),
            ],
            const SizedBox(height: AppTheme.spacingLg),
            _Divider(),
            const SizedBox(height: AppTheme.spacingLg),
            _ReceiptRow(
              icon: Icons.payment_outlined,
              iconColor: context.colors.textSecondary,
              label: 'Paiement',
              value: ride.paymentMethod ?? 'Espèces',
            ),
            if (ride.transactionId != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              _ReceiptRow(
                icon: Icons.tag,
                iconColor: context.colors.textSecondary,
                label: 'Transaction',
                value: ride.transactionId!,
              ),
            ],
            const SizedBox(height: AppTheme.spacingXl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: context.colors.greyExtraLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total payé',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    ride.price.toCFA,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Fermer',
                  style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(color: context.colors.greyLight, thickness: 1);
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
              ),
              Text(
                value,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
