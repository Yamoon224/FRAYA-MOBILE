library;

import 'package:flutter/material.dart';

import '../../../../core/services/address_formatter_service.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../shared/widgets/route_location_item.dart';
import 'driver_home_active_ride_actions.dart';
import 'driver_home_active_ride_card_parts.dart';
import 'driver_home_ride_card_parts.dart';

class DriverHomeActiveRideCard extends StatelessWidget {
  const DriverHomeActiveRideCard({
    super.key,
    required this.ride,
    required this.isBusy,
    required this.onCallPassenger,
    required this.onOpenPassengerWhatsApp,
    required this.onArrived,
    required this.onStart,
    required this.onComplete,
    required this.onCancel,
  });

  final DriverRide ride;
  final bool isBusy;
  final Future<void> Function() onCallPassenger;
  final Future<void> Function() onOpenPassengerWhatsApp;
  final Future<void> Function() onArrived;
  final Future<void> Function() onStart;
  final Future<void> Function() onComplete;
  final Future<void> Function() onCancel;
  static const _addressFormatter = AddressFormatterService();

  @override
  Widget build(BuildContext context) {
    final distanceText = ride.estimatedDistanceKm == null
        ? '-- km'
        : '${ride.estimatedDistanceKm!.toStringAsFixed(1)} km';
    final durationText = ride.estimatedDurationMin == null
        ? '-- min'
        : '${ride.estimatedDurationMin} min';
    final pickupAddress = _addressFormatter.bestDisplayAddress([
      ride.pickupAddress,
    ], fallback: 'Point de départ');
    final destinationAddress = _addressFormatter.bestDisplayAddress([
      ride.destinationAddress,
    ], fallback: 'Destination');

    return DriverHomeRideCardShell(
      title: null,
      isFlat: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DriverHomeActiveRidePassengerHeader(
            name: ride.passengerName,
            photoUrl: ride.passengerPhoto,
            passengerRating: ride.passengerRating,
            passengerRidesCount: ride.passengerRidesCount,
            onCallPassenger: () {
              onCallPassenger();
            },
            onOpenPassengerWhatsApp: () {
              onOpenPassengerWhatsApp();
            },
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          const SizedBox(height: 14),
          RouteLocationItem(
            label: 'Point de départ',
            location: pickupAddress,
            icon: Icons.location_on,
            iconBackground: Color(0xFFCFF3DA),
            iconColor: Color(0xFF16A34A),
          ),
          const SizedBox(height: 12),
          RouteLocationItem(
            label: 'Destination',
            location: destinationAddress,
            icon: Icons.place,
            iconBackground: Color(0xFFF8E29A),
            iconColor: Color(0xFFC58B0F),
          ),
          const SizedBox(height: 16),
          DriverHomeActiveRideSummaryPanel(
            distance: distanceText,
            duration: durationText,
            amount: ride.estimatedPrice.toCFA,
          ),
          if (ride.status == RideStatus.arrived) ...[
            const SizedBox(height: 12),
            DriverHomeActiveRideWaitingTimePanel(arrivedAt: ride.arrivedAt),
          ],
          const SizedBox(height: 18),
          ..._buildActions(),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    switch (ride.status) {
      case RideStatus.accepted:
        return _actionGroup(
          primaryLabel: 'Je suis arrivé',
          primaryIcon: Icons.place_outlined,
          onPrimary: onArrived,
        );
      case RideStatus.arrived:
        return _actionGroup(
          primaryLabel: 'Démarrer la course',
          primaryIcon: Icons.near_me_rounded,
          onPrimary: onStart,
        );
      case RideStatus.inProgress:
        return [
          DriverHomePrimaryRideActionButton(
            label: 'Terminer la course',
            icon: Icons.check_circle_outline_rounded,
            isDisabled: isBusy,
            onTap: onComplete,
          ),
          const SizedBox(height: 12),
          DriverHomeCancelRideTextAction(isDisabled: isBusy, onTap: onCancel),
        ];
      default:
        return const [];
    }
  }

  List<Widget> _actionGroup({
    required String primaryLabel,
    required IconData primaryIcon,
    required Future<void> Function() onPrimary,
  }) {
    return [
      DriverHomePrimaryRideActionButton(
        label: primaryLabel,
        icon: primaryIcon,
        isDisabled: isBusy,
        onTap: onPrimary,
      ),
      const SizedBox(height: 12),
      DriverHomeCancelRideTextAction(isDisabled: isBusy, onTap: onCancel),
    ];
  }
}
