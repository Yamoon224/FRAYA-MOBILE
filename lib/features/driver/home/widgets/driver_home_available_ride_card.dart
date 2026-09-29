library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/address_formatter_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../shared/widgets/fraya_button.dart';
import 'driver_home_ride_card_parts.dart';

class DriverHomeAvailableRideCard extends StatelessWidget {
  const DriverHomeAvailableRideCard({
    super.key,
    required this.ride,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final DriverRide ride;
  final bool isBusy;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;
  static const _addressFormatter = AddressFormatterService();

  @override
  Widget build(BuildContext context) {
    final pickupAddress = _addressFormatter.bestDisplayAddress([
      ride.pickupAddress,
    ], fallback: 'Point de départ');
    final destinationAddress = _addressFormatter.bestDisplayAddress([
      ride.destinationAddress,
    ], fallback: 'Destination');
    return DriverHomeRideCardShell(
      title: ride.passengerName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DriverHomeRideAddressRow(
            icon: Icons.my_location,
            text: pickupAddress,
          ),
          const SizedBox(height: 6),
          DriverHomeRideAddressRow(
            icon: Icons.flag_outlined,
            text: destinationAddress,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: DriverHomeRideInfoChip(
                  icon: Icons.payments_outlined,
                  text: ride.estimatedPrice.toCFA,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: DriverHomeRideInfoChip(
                  icon: Icons.schedule_rounded,
                  text: ride.createdAt?.timeAgo ?? 'Nouvelle',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: FrayaButton(
                  label: 'Refuser',
                  variant: FrayaButtonVariant.outline,
                  onPressed: isBusy ? null : () => onDecline(),
                  leftIcon: Icons.close_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: FrayaButton(
                  label: 'Accepter',
                  onPressed: isBusy ? null : () => onAccept(),
                  isLoading: isBusy,
                  leftIcon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverHomeEmptyState extends StatelessWidget {
  const DriverHomeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.grey),
          const SizedBox(height: AppTheme.spacingSm),
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
