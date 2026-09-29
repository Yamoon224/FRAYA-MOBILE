import 'package:flutter/material.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';

class RideItineraryTimeline extends StatelessWidget {
  final Ride ride;
  const RideItineraryTimeline({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ItinÃ©raire',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _LocationPoint(
            icon: Icons.circle,
            iconColor: AppColors.success,
            label: 'Prise en charge',
            address: ride.departureAddress,
            showLine: true,
          ),
          _LocationPoint(
            icon: Icons.panorama_fish_eye,
            iconColor: const Color(0xFFD4A843),
            label: 'Destination',
            address: ride.arrivalAddress,
            showLine: false,
          ),
        ],
      ),
    );
  }
}

class _LocationPoint extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final bool showLine;

  const _LocationPoint({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: iconColor),
            ),
            if (showLine)
              Container(width: 1.5, height: 60, color: context.colors.greyLight),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.xs.copyWith(color: context.colors.textTertiary),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
