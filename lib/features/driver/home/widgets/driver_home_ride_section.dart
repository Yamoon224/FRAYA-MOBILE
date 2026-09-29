library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/driver_ride.dart';
import 'driver_home_active_ride_card.dart';
import 'driver_home_available_ride_card.dart';

class DriverHomeRideSection extends StatelessWidget {
  const DriverHomeRideSection({
    super.key,
    required this.isOnline,
    required this.isBusy,
    required this.availableRides,
    required this.activeRide,
    required this.onAccept,
    required this.onDecline,
    required this.onCallPassenger,
    required this.onOpenPassengerWhatsApp,
    required this.onArrived,
    required this.onStart,
    required this.onComplete,
    required this.onCancel,
  });

  final bool isOnline;
  final bool isBusy;
  final List<DriverRide> availableRides;
  final DriverRide? activeRide;
  final Future<void> Function(DriverRide ride) onAccept;
  final Future<void> Function(DriverRide ride) onDecline;
  final Future<void> Function(DriverRide ride) onCallPassenger;
  final Future<void> Function(DriverRide ride) onOpenPassengerWhatsApp;
  final Future<void> Function(DriverRide ride) onArrived;
  final Future<void> Function(DriverRide ride) onStart;
  final Future<void> Function(DriverRide ride) onComplete;
  final Future<void> Function(DriverRide ride) onCancel;

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return const DriverHomeEmptyState(
        icon: Icons.power_settings_new_rounded,
        title: 'Mode hors ligne',
        message: 'Activez votre disponibilite pour recevoir des courses.',
      );
    }
    if (activeRide != null) {
      return DriverHomeActiveRideCard(
        ride: activeRide!,
        isBusy: isBusy,
        onCallPassenger: () => onCallPassenger(activeRide!),
        onOpenPassengerWhatsApp: () => onOpenPassengerWhatsApp(activeRide!),
        onArrived: () => onArrived(activeRide!),
        onStart: () => onStart(activeRide!),
        onComplete: () => onComplete(activeRide!),
        onCancel: () => onCancel(activeRide!),
      );
    }
    if (availableRides.isEmpty) {
      return const DriverHomeEmptyState(
        icon: Icons.radio_button_checked_rounded,
        title: 'En attente de demandes',
        message: 'Aucune course disponible pour le moment.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Demandes disponibles', style: AppTextStyles.h4),
        const SizedBox(height: AppTheme.spacingSm),
        for (final ride in availableRides.take(3)) ...[
          DriverHomeAvailableRideCard(
            ride: ride,
            isBusy: isBusy,
            onAccept: () => onAccept(ride),
            onDecline: () => onDecline(ride),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
        if (availableRides.length > 3)
          Text(
            '${availableRides.length - 3} autre(s) demande(s) en attente.',
            style: AppTextStyles.xs,
          ),
      ],
    );
  }
}
