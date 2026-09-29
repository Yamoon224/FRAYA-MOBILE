library;

import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/address_formatter_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../shared/models/user_stats_view_data.dart';
import 'driver_home_incoming_request_shared.dart';

class IncomingRequestContent extends StatelessWidget {
  const IncomingRequestContent({
    super.key,
    required this.ride,
    required this.pendingCount,
    required this.secondsRemaining,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final DriverRide ride;
  final int pendingCount;
  final int secondsRemaining;
  final bool isBusy;
  final Future<void> Function() onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IncomingHeader(secondsRemaining: secondsRemaining),
        Text(
          pendingCount > 1
              ? '$pendingCount demandes attendent votre reponse.'
              : 'Acceptez ou ignorez cette demande.',
          style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Expanded(
          child: SingleChildScrollView(child: _IncomingRideCard(ride: ride)),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        IncomingActions(
          isBusy: isBusy,
          onAccept: onAccept,
          onDecline: onDecline,
        ),
      ],
    );
  }
}

class _IncomingHeader extends StatelessWidget {
  const _IncomingHeader({required this.secondsRemaining});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Container(
        //   width: 50,
        //   height: 3,
        //   margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
        //   decoration: BoxDecoration(
        //     color: AppColors.greyLight,
        //     borderRadius: BorderRadius.circular(999),
        //   ),
        // ),
        Expanded(
          child: Text(
            'Nouvelle demande de course',
            style: AppTextStyles.h1.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Container(
          constraints: const BoxConstraints(minWidth: 58),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2C8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFFDB913)),
          ),
          child: Text(
            '${secondsRemaining}s',
            style: AppTextStyles.buttonSmall.copyWith(
              color: AppColors.primaryDark,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _IncomingRideCard extends StatelessWidget {
  const _IncomingRideCard({required this.ride});

  final DriverRide ride;
  static const _addressFormatter = AddressFormatterService();

  @override
  Widget build(BuildContext context) {
    final pickupAddress = _addressFormatter.bestDisplayAddress([
      ride.pickupAddress,
    ], fallback: 'Point de départ');
    final destinationAddress = _addressFormatter.bestDisplayAddress([
      ride.destinationAddress,
    ], fallback: 'Destination');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.border),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PassengerHeader(ride: ride),
          const SizedBox(height: AppTheme.spacingLg),
          AddressTile(
            icon: Icons.my_location_rounded,
            iconColor: AppColors.success,
            background: context.colors.successBackground,
            label: 'Point de départ',
            value: pickupAddress,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          AddressTile(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.primaryDark,
            background: const Color(0xFFFFF2C8),
            label: 'Destination',
            value: destinationAddress,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: context.colors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: MetricCell(
                    label: 'Distance',
                    value: ride.estimatedDistanceKm == null
                        ? '-- km'
                        : '${ride.estimatedDistanceKm!.toStringAsFixed(1)} km',
                  ),
                ),
                const MetricDivider(),
                Expanded(
                  child: MetricCell(
                    label: 'Temps',
                    value: ride.estimatedDurationMin == null
                        ? '-- min'
                        : '${ride.estimatedDurationMin} min',
                  ),
                ),
                const MetricDivider(),
                Expanded(
                  child: MetricCell(
                    label: 'Gain estime',
                    value: ride.estimatedPrice.toCFA,
                    valueColor: AppColors.primaryDark,
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

class _PassengerHeader extends StatelessWidget {
  const _PassengerHeader({required this.ride});

  final DriverRide ride;

  @override
  Widget build(BuildContext context) {
    final stats = UserStatsViewData(
      rating: ride.passengerRating,
      ridesCount: ride.passengerRidesCount,
    );
    return Row(
      children: [
        _PassengerAvatar(photoUrl: ride.passengerPhoto),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.passengerName,
                style: AppTextStyles.h2.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...List.generate(5, (index) {
                    final isFilled = stats.hasRating && index < stats.starCount;
                    return Icon(
                      Icons.star_rounded,
                      color: isFilled
                          ? const Color(0xFFD4A843)
                          : context.colors.greyLight,
                      size: 16,
                    );
                  }),
                  Text(stats.ratingLabel, style: AppTextStyles.body),
                  Text(
                    '(${stats.ridesCountLabel})',
                    style: AppTextStyles.small,
                  ),
                  if ((ride.passengerPhone ?? '').isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        ride.passengerPhone!,
                        style: AppTextStyles.small,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const VerifiedChip(),
      ],
    );
  }
}

class _PassengerAvatar extends StatelessWidget {
  const _PassengerAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = Env.resolveProfilePhotoUrl(photoUrl);
    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AppColors.goldGradient,
        shape: BoxShape.circle,
      ),
      child: resolvedUrl == null
          ? const Icon(Icons.person_outline_rounded, size: 28)
          : Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.person_outline_rounded, size: 28),
            ),
    );
  }
}
