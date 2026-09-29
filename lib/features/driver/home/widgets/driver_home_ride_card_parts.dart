library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/ride_status.dart';

class DriverHomeRideCardShell extends StatelessWidget {
  const DriverHomeRideCardShell({
    super.key,
    this.title,
    required this.child,
    this.isFlat = false,
  });

  final String? title;
  final Widget child;
  final bool isFlat;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.trim().isNotEmpty;
    if (isFlat) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            Text(
              title!,
              style: AppTextStyles.h4.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
          ],
          child,
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            Text(
              title!,
              style: AppTextStyles.h4.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
          ],
          child,
        ],
      ),
    );
  }
}

class DriverHomeRideStatusBadge extends StatelessWidget {
  const DriverHomeRideStatusBadge({super.key, required this.status});

  final RideStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RideStatus.accepted => const Color(0xFF047857),
      RideStatus.arrived => AppColors.primaryDark,
      RideStatus.inProgress => const Color(0xFF047857),
      _ => context.colors.textPrimary,
    };

    final background = switch (status) {
      RideStatus.accepted => const Color(0xFFE9FFF1),
      RideStatus.arrived => const Color(0xFFFFF4CC),
      RideStatus.inProgress => const Color(0xFFEAFBF2),
      _ => context.colors.greyLight,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _driverLabel,
        style: AppTextStyles.xs.copyWith(
          color: color,
          fontSize: 10.8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String get _driverLabel {
    switch (status) {
      case RideStatus.accepted:
        return 'En route vers le passager';
      case RideStatus.arrived:
        return 'Arrivé - En attente';
      case RideStatus.inProgress:
        return 'Course en cours';
      case RideStatus.completed:
        return 'Course terminée';
      case RideStatus.cancelled:
        return 'Course annulée';
      case RideStatus.pending:
        return 'Nouvelle demande';
    }
  }
}

class DriverHomeRideAddressRow extends StatelessWidget {
  const DriverHomeRideAddressRow({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: context.colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class DriverHomeRideInfoChip extends StatelessWidget {
  const DriverHomeRideInfoChip({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF48A84F),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF0C4F2A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.xs.copyWith(
                color: const Color(0xFF082A12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
