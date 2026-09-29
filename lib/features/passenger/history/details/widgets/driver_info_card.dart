import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/core/services/passenger_contact_launcher_service.dart';
import 'package:fraya_mobile/shared/models/user_stats_view_data.dart';
import 'package:fraya_mobile/shared/widgets/app_snack_bar.dart';
import '../../providers/locally_rated_rides_provider.dart';
import '../../widgets/history_ride_rating_sheet.dart';

class DriverInfoCard extends ConsumerWidget {
  final Ride ride;
  const DriverInfoCard({super.key, required this.ride});

  static const _contactService = PassengerContactLauncherService();

  Future<void> _handleCall(BuildContext context) async {
    final phone = ride.driverPhone;
    if (phone == null || phone.isEmpty) return;
    final ok = await _contactService.launchPhoneCall(phone);
    if (!ok && context.mounted) {
      AppSnackBar.showError(context, 'Numéro du chauffeur indisponible.');
    }
  }

  Future<void> _handleWhatsApp(BuildContext context) async {
    final phone = ride.driverPhone;
    if (phone == null || phone.isEmpty) return;
    final ok = await _contactService.launchWhatsApp(phone);
    if (!ok && context.mounted) {
      AppSnackBar.showError(
        context,
        'Impossible d\'ouvrir WhatsApp sans numéro valide.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note de profil du chauffeur (moyenne) — souvent indisponible côté course.
    final profileStats = UserStatsViewData.fromMap({
      'rating': ride.driverProfileRating,
      'coursesCount': ride.driverRidesCount,
    });
    final hasPhone =
        ride.driverPhone != null && ride.driverPhone!.trim().isNotEmpty;
    final locallyRated = ref
        .watch(locallyRatedRideIdsProvider)
        .contains(ride.id);
    final canRate = ride.canRateDriver && !locallyRated;
    final receivedRating = ride.passengerRatingFromDriver;
    final receivedStars = receivedRating?.round().clamp(0, 5) ?? 0;
    final hasReceivedRating = receivedRating != null && receivedRating > 0;
    final passengerCommentFromDriver = ride.passengerCommentFromDriver?.trim();
    final passengerRatingStars =
        ride.driverRatingFromPassenger?.round().clamp(0, 5) ?? 0;
    final driverCommentFromPassenger = ride.driverCommentFromPassenger?.trim();

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
            'Informations du chauffeur',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Profil + boutons contact
          Row(
            children: [
              _DriverAvatar(isVerified: ride.isDriverVerified),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ride.driverName ?? 'Chauffeur',
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ride.isDriverVerified) ...[
                          const SizedBox(width: 8),
                          const _VerifiedBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFD4A843),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profileStats.ratingLabel,
                          style: AppTextStyles.small.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• ${profileStats.ridesCountLabel} courses',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasPhone) ...[
                const SizedBox(width: 8),
                _ActionCircle(
                  icon: Icons.call_outlined,
                  onTap: () => _handleCall(context),
                ),
                const SizedBox(width: 8),
                _ActionCircle(
                  iconWidget: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  onTap: () => _handleWhatsApp(context),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Véhicule
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Véhicule',
                        style: AppTextStyles.xs.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.vehicleModel ?? 'Modèle inconnu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Couleur : ${ride.vehicleColor ?? "Inconnue"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.xs.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Plaque',
                      style: AppTextStyles.xs.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride.licensePlate ?? '---',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: context.colors.greyExtraLight),
          const SizedBox(height: 12),

          // Note recue du chauffeur.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Note reçue du chauffeur',
                style: AppTextStyles.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final isFilled = hasReceivedRating && index < receivedStars;
                  return Icon(
                    Icons.star,
                    color: isFilled
                        ? const Color(0xFFD4A843)
                        : context.colors.greyLight,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          if (passengerCommentFromDriver != null &&
              passengerCommentFromDriver.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '"$passengerCommentFromDriver"',
              style: AppTextStyles.body.copyWith(
                color: context.colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (canRate)
            Align(
              alignment: Alignment.centerRight,
              child: _RateButton(
                onTap: () => HistoryRideRatingSheet.show(context, ride.id),
              ),
            )
          else if (ride.hasRated) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Votre note au chauffeur',
                  style: AppTextStyles.body.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    final isFilled = index < passengerRatingStars;
                    return Icon(
                      Icons.star,
                      color: isFilled
                          ? const Color(0xFFD4A843)
                          : context.colors.greyLight,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            if (driverCommentFromPassenger != null &&
                driverCommentFromPassenger.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '"$driverCommentFromPassenger"',
                style: AppTextStyles.body.copyWith(
                  color: context.colors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.star_outline_rounded, size: 18),
      label: const Text('Noter'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        textStyle: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  final bool isVerified;
  const _DriverAvatar({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.greyLight, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/driver_mock.png',
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                child: Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 30,
                    color: Colors.black87,
                  ),
                ),
              );
            },
          ),
        ),
        if (isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 18,
              ),
            ),
          ),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.successBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 10, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Vérifié',
            style: AppTextStyles.xs.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({this.icon, this.iconWidget, required this.onTap})
    : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        height: 38,
        width: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: iconWidget ?? Icon(icon, size: 18, color: AppColors.primaryDark),
      ),
    );
  }
}
