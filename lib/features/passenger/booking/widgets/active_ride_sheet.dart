import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fraya_mobile/domain/models/ride_status.dart';

import '../../../../core/services/address_formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../../../shared/widgets/route_location_item.dart';
import '../providers/booking_provider.dart';
import 'active_ride/arrival_progress_bar.dart';
import 'active_ride/cancel_ride_sheet.dart';
import 'active_ride/driver_info_card.dart';
import 'active_ride/real_time_trip_card.dart';
import 'active_ride/sos_alert_section.dart';
import 'active_ride/vehicle_info_card.dart';

class ActiveRideSheet extends ConsumerWidget {
  const ActiveRideSheet({super.key, this.scrollController, this.onRefresh});

  static const _addressFormatter = AddressFormatterService();

  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(activeRideControllerProvider);
    final liveMetrics = ref.watch(activeRideLiveMetricsControllerProvider);
    final arrivalProgress = ref.watch(activeRideArrivalProgressProvider);
    final pickup = ref.watch(selectedPickupProvider);
    final destination = ref.watch(selectedDestinationProvider);
    final formattedAddress = ref.watch(formattedAddressProvider);

    if (ride == null) return const SizedBox.shrink();

    final pickupDisplay = _addressFormatter.bestDisplayAddress(<String?>[
      pickup?.address,
      ride.pickupAddress,
      formattedAddress,
    ], fallback: 'Position actuelle');
    final destinationDisplay = _addressFormatter.bestDisplayAddress(<String?>[
      destination?.address,
      ride.destinationAddress,
      destination?.name,
    ], fallback: 'Destination non définie');

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
        boxShadow: AppColors.shadowLg,
      ),
      child: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            context.horizontalPagePadding,
            AppTheme.spacingMd,
            context.horizontalPagePadding,
            AppTheme.spacingLg,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: context.colors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            DriverInfoCard(ride: ride),
            const SizedBox(height: AppTheme.spacingLg),
            VehicleInfoCard(ride: ride),
            const SizedBox(height: AppTheme.spacingXl),
            if (ride.status == RideStatus.inProgress) ...[
              RealTimeTripCard(
                remainingTime: liveMetrics.etaText,
                remainingDistance: liveMetrics.distanceText,
                source: liveMetrics.source,
              ),
            ] else if (ride.status != RideStatus.arrived &&
                ride.status != RideStatus.completed) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Arrivée du chauffeur',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      liveMetrics.etaText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ArrivalProgressBar(
                progress: arrivalProgress.progress,
                gradient: AppColors.goldGradient,
                isIndeterminate: arrivalProgress.isIndeterminate,
              ),
            ],
            const SizedBox(height: AppTheme.spacingXl),
            RouteLocationItem(
              iconBackground: context.colors.isDark ? const Color(0xFF1B4332) : const Color(0xFFDDF6EA),
              iconColor: AppColors.success,
              icon: Icons.location_on,
              label: 'Point de départ',
              location: pickupDisplay,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            RouteLocationItem(
              iconBackground: context.colors.isDark ? const Color(0xFF3D2B00) : const Color(0xFFFFE9B3),
              iconColor: const Color(0xFFCBA153),
              icon: Icons.place,
              label: 'Destination',
              location: destinationDisplay,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            if (ride.status == RideStatus.inProgress) ...[
              SosAlertSection(rideId: ride.rideId),
              const SizedBox(height: AppTheme.spacingXl),
            ],
            if (ride.status == RideStatus.accepted)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                child: Center(
                  child: TextButton(
                    onPressed: () => CancelRideSheet.show(context),
                    child: Text(
                      'Annuler la course',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.spacing2xl),
          ],
        ),
      ),
    );
  }
}
