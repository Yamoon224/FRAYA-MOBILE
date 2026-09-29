library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/address_formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/models/driver_ride_earnings.dart';
import '../../../../domain/models/ride_status.dart';

class DriverHistoryRideCard extends StatelessWidget {
  const DriverHistoryRideCard({
    super.key,
    required this.ride,
    this.showCommissionBreakdown = false,
  });

  final DriverRide ride;
  final bool showCommissionBreakdown;

  static const _addressFormatter = AddressFormatterService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final when =
        ride.historyDate ?? ride.updatedAt ?? ride.createdAt ?? DateTime.now();
    final startedAt = ride.startedAt;
    final endedAt = ride.endedAt;
    final amount = ride.finalPrice ?? ride.estimatedPrice;
    final pickupAddress = _addressFormatter.bestDisplayAddress([
      ride.pickupAddress,
    ], fallback: 'Point de départ');
    final destinationAddress = _addressFormatter.bestDisplayAddress([
      ride.destinationAddress,
    ], fallback: 'Destination');
    final isCancelled = ride.status == RideStatus.cancelled;
    final amountColor = isCancelled
        ? context.colors.textSecondary
        : AppColors.primaryDark;
    final ratingFromPassenger = ride.driverRatingFromPassenger;
    final hasPassengerFeedback =
        (ratingFromPassenger != null && ratingFromPassenger > 0) ||
        (ride.driverCommentFromPassenger != null &&
            ride.driverCommentFromPassenger!.trim().isNotEmpty);

    final surfaceColor = context.colors.surface;
    final innerBg = context.colors.background;
    final textPrimary = context.colors.textPrimary;
    final textSecondary = context.colors.textSecondary;

    return Container(
      padding: EdgeInsets.all(
        context.responsiveValue<double>(
          compact: 16,
          phone: 18,
          largePhone: 18,
          tablet: 20,
        ),
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : AppColors.shadowMd,
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _formatMoment(when),
                          style: AppTextStyles.small.copyWith(
                            color: textSecondary,
                          ),
                        ),
                        _DriverHistoryStatusBadge(
                          status: ride.status,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      amount.toCFA,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 18,
                        color: amountColor,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatMoment(when),
                      style: AppTextStyles.small.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ),
                  _DriverHistoryStatusBadge(
                    status: ride.status,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      amount.toCFA,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 18,
                        color: amountColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (showCommissionBreakdown &&
              ride.commissionPrice != null &&
              !isCancelled) ...[
            const SizedBox(height: 8),
            _CommissionBreakdown(
              ride: ride,
              grossAmount: amount,
              isDark: isDark,
              innerBg: innerBg,
            ),
          ],
          const SizedBox(height: 12),
          _HistoryMetaLine(
            icon: Icons.calendar_today_outlined,
            label: 'Date de la course',
            value: _formatDate(when),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          if (!isCancelled) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final start = _HistoryMetaLine(
                  icon: Icons.play_circle_outline,
                  label: 'Debut',
                  value: _formatMoment(startedAt),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
                final end = _HistoryMetaLine(
                  icon: Icons.stop_circle_outlined,
                  label: 'Fin',
                  value: _formatMoment(endedAt),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
                if (constraints.maxWidth < 180) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [start, const SizedBox(height: 12), end],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: start),
                    const SizedBox(width: 16),
                    Expanded(child: end),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(
                Icons.near_me_outlined,
                size: 18,
                color: textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$pickupAddress  -  $destinationAddress',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(color: textPrimary),
                ),
              ),
            ],
          ),
          if (ride.keyRide != null) ...[
            const SizedBox(height: 8),
            _RideKeyRow(keyRide: ride.keyRide!, textSecondary: textSecondary),
          ],
          if (!isCancelled) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.access_time_rounded,
                  text: _formatDuration(ride.estimatedDurationMin),
                  isDark: isDark,
                  innerBg: innerBg,
                  textColor: textPrimary,
                  iconColor: textSecondary,
                ),
                _InfoPill(
                  icon: Icons.route_outlined,
                  text: _formatDistance(ride.estimatedDistanceKm),
                  isDark: isDark,
                  innerBg: innerBg,
                  textColor: textPrimary,
                  iconColor: textSecondary,
                ),
                _InfoPill(
                  icon: Icons.person_outline_rounded,
                  text: ride.passengerName,
                  isDark: isDark,
                  innerBg: innerBg,
                  textColor: textPrimary,
                  iconColor: textSecondary,
                ),
              ],
            ),
            if (hasPassengerFeedback) ...[
              const SizedBox(height: 10),
              _PassengerFeedback(
                ride: ride,
                isDark: isDark,
                innerBg: innerBg,
                textSecondary: textSecondary,
                textPrimary: textPrimary,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final raw = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date.toLocal());
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _formatMoment(DateTime? date) {
    if (date == null) return '--:--';
    return DateFormat('HH:mm', 'fr_FR').format(date.toLocal());
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '-- min';
    return '$minutes min';
  }

  String _formatDistance(double? kilometers) {
    if (kilometers == null) return '-- km';
    final formatted = kilometers % 1 == 0
        ? kilometers.toStringAsFixed(0)
        : kilometers.toStringAsFixed(1);
    return '$formatted km';
  }
}

class _PassengerFeedback extends StatelessWidget {
  const _PassengerFeedback({
    required this.ride,
    required this.isDark,
    required this.innerBg,
    required this.textSecondary,
    required this.textPrimary,
  });

  final DriverRide ride;
  final bool isDark;
  final Color innerBg;
  final Color textSecondary;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    final rating = ride.driverRatingFromPassenger;
    final stars = rating?.round().clamp(0, 5) ?? 0;
    final comment = ride.driverCommentFromPassenger?.trim();
    final emptyStarColor = context.colors.greyLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Avis reçu',
                style: AppTextStyles.xs.copyWith(color: textSecondary),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  final isFilled =
                      rating != null && rating > 0 && index < stars;
                  return Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: isFilled
                        ? const Color(0xFFD4A843)
                        : emptyStarColor,
                  );
                }),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"$comment"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.xs.copyWith(
                color: textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryMetaLine extends StatelessWidget {
  const _HistoryMetaLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.xs.copyWith(color: textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFD4A843)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DriverHistoryStatusBadge extends StatelessWidget {
  const _DriverHistoryStatusBadge({
    required this.status,
    required this.isDark,
  });

  final RideStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == RideStatus.cancelled;
    final bgColor = isCancelled
        ? (isDark
              ? AppColors.darkSurface
              : const Color(0xFFFDECEC))
        : (isDark
              ? AppColors.darkSuccessBackground
              : const Color(0xFFF2F7E8));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCancelled ? 'Annulee' : 'Terminee',
        style: AppTextStyles.xs.copyWith(
          color: isCancelled ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }
}

class _CommissionBreakdown extends StatelessWidget {
  const _CommissionBreakdown({
    required this.ride,
    required this.grossAmount,
    required this.isDark,
    required this.innerBg,
  });

  final DriverRide ride;
  final double grossAmount;
  final bool isDark;
  final Color innerBg;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? AppColors.darkBorder
        : const Color(0xFFD6D8DC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _BreakdownItem(
            label: 'Brut',
            value: grossAmount.toCFA,
            color: context.colors.textPrimary,
          ),
          _BreakdownDivider(color: dividerColor),
          _BreakdownItem(
            label: 'Commission',
            value: '- ${ride.driverCommissionAmount.toCFA}',
            color: AppColors.error,
          ),
          _BreakdownDivider(color: dividerColor),
          _BreakdownItem(
            label: 'Net',
            value: ride.driverNetEarnings.toCFA,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.xs.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownDivider extends StatelessWidget {
  const _BreakdownDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _RideKeyRow extends StatelessWidget {
  const _RideKeyRow({required this.keyRide, required this.textSecondary});

  final String keyRide;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.tag_outlined,
          size: 14,
          color: textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Réf : $keyRide',
          style: AppTextStyles.xs.copyWith(color: textSecondary),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.isDark,
    required this.innerBg,
    required this.textColor,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final bool isDark;
  final Color innerBg;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 168),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.xs.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
