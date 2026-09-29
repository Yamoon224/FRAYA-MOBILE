import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/ride_model.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../providers/locally_rated_rides_provider.dart';
import 'history_ride_rating_sheet.dart';

class RideHistoryTile extends ConsumerWidget {
  final Ride ride;

  const RideHistoryTile({super.key, required this.ride});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final rideDate = DateTime(date.year, date.month, date.day);

    if (rideDate == today) {
      return "Aujourd'hui";
    } else if (rideDate == yesterday) {
      return "Hier";
    } else {
      return DateFormat('dd MMM', 'fr_FR').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('HH:mm');
    final isCancelled = ride.status == RideStatus.cancelled;
    final locallyRated = isCancelled
        ? false
        : ref.watch(locallyRatedRideIdsProvider).contains(ride.id);
    final driverCommentFromPassenger = ride.driverCommentFromPassenger?.trim();

    return InkWell(
      onTap: isCancelled
          ? null
          : () => context.pushNamed(
              RouteNames.rideDetails,
              queryParameters: {'id': ride.id},
            ),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // --- Header: Date/Time & Prix ou badge annulée ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(ride.date)}  •  ',
                        style: AppTextStyles.small.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat.format(ride.date),
                        style: AppTextStyles.small.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (isCancelled)
                    _CancelledBadge()
                  else
                    Text(
                      '${AppDateUtils.formatPrice(ride.price)} FCFA',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Path Section ---
              _LocationSection(
                departure: ride.departureAddress,
                arrival: ride.arrivalAddress,
              ),

              if (isCancelled && ride.keyRide != null) ...[
                const SizedBox(height: 10),
                _RideKeyRow(keyRide: ride.keyRide!),
              ],

              if (!isCancelled) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: context.colors.greyLight),
                const SizedBox(height: 12),

                // --- Driver Section ---
                Row(
                  children: [
                    _DriverAvatar(),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.driverName ?? 'En attente...',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ride.vehicleModel ?? ride.vehicleRange,
                            style: AppTextStyles.xs.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ride.hasRated)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ride.driverRatingFromPassenger!.toStringAsFixed(1),
                            style: AppTextStyles.small.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else if (ride.canRateDriver && !locallyRated)
                      _RateButton(
                        onTap: () =>
                            HistoryRideRatingSheet.show(context, ride.id),
                      ),
                  ],
                ),
                if (driverCommentFromPassenger != null &&
                    driverCommentFromPassenger.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '"$driverCommentFromPassenger"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        color: context.colors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_outline_rounded,
              color: AppColors.primaryDark,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Noter',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final String departure;
  final String arrival;

  const _LocationSection({required this.departure, required this.arrival});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LocationRow(
          color: AppColors.success,
          address: departure,
          isCircle: false,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 4.5, top: 2, bottom: 2),
            height: 16,
            width: 1,
            color: context.colors.greyLight,
          ),
        ),
        _LocationRow(
          color: AppColors.primaryDark,
          address: arrival,
          isCircle: true,
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final Color color;
  final String address;
  final bool isCircle;

  const _LocationRow({
    required this.color,
    required this.address,
    required this.isCircle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isCircle ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isCircle ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            address,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: const Center(
        child: Icon(Icons.directions_car, color: AppColors.error, size: 18),
      ),
    );
  }
}

class _CancelledBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.isDark ? const Color(0xFF4A1A1A) : const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Annulée',
        style: AppTextStyles.xs.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _RideKeyRow extends StatelessWidget {
  const _RideKeyRow({required this.keyRide});

  final String keyRide;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.tag_outlined,
          size: 14,
          color: context.colors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Réf : $keyRide',
          style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}
