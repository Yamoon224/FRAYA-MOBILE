import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/active_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../passenger/booking/providers/active_ride_check_provider.dart';
import '../../../passenger/booking/providers/booking_provider.dart';
import '../../../passenger/booking/providers/pending_search_session_provider.dart';

class ActiveRideBanner extends ConsumerWidget {
  const ActiveRideBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);
    final activeRide = _activeRide(ref);
    final pendingSession = ref.watch(pendingSearchSessionStoreProvider).read();
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

    final text = activeRide == null
        ? (flowState == BookingFlowState.searching && pendingSession != null
              ? 'Recherche d\'un chauffeur...'
              : null)
        : _activeRideText(activeRide.status);

    if (text == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        if (activeRide != null) {
          ref
              .read(bookingFlowProvider.notifier)
              .restoreFromActiveRide(activeRide);
        }
        context.pushNamed(RouteNames.vehicleSelection);
      },
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

  ActiveRide? _activeRide(WidgetRef ref) {
    final controllerRide = ref.watch(activeRideControllerProvider);
    if (_isRestorableRide(controllerRide)) return controllerRide;
    final checkedRide = ref.watch(activeRideCheckProvider).asData?.value;
    if (_isRestorableRide(checkedRide)) return checkedRide;
    return null;
  }

  bool _isRestorableRide(ActiveRide? ride) {
    return ride != null &&
        (ride.status == RideStatus.accepted ||
            ride.status == RideStatus.arrived ||
            ride.status == RideStatus.inProgress);
  }

  String? _activeRideText(RideStatus status) {
    return switch (status) {
      RideStatus.accepted => 'Chauffeur en route',
      RideStatus.arrived => 'Votre chauffeur est arrivé',
      RideStatus.inProgress => 'Course en cours',
      _ => null,
    };
  }
}
