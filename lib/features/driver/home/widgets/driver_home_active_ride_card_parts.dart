library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/models/user_stats_view_data.dart';

part 'driver_home_active_ride_card_metrics.dart';

class DriverHomeActiveRidePassengerHeader extends StatelessWidget {
  const DriverHomeActiveRidePassengerHeader({
    super.key,
    required this.name,
    this.photoUrl,
    required this.passengerRating,
    required this.passengerRidesCount,
    required this.onCallPassenger,
    required this.onOpenPassengerWhatsApp,
  });

  final String name;
  final String? photoUrl;
  final double? passengerRating;
  final int? passengerRidesCount;
  final VoidCallback onCallPassenger;
  final VoidCallback onOpenPassengerWhatsApp;

  @override
  Widget build(BuildContext context) {
    final stats = UserStatsViewData(
      rating: passengerRating,
      ridesCount: passengerRidesCount,
    );
    return Row(
      children: [
        _PassengerAvatar(photoUrl: photoUrl, size: 58, iconSize: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 17,
                  color: context.colors.isDark ? const Color(0xFFE8E8E8) : const Color(0xFF202020),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return _StarIcon(
                      isEmpty: !stats.hasRating || index >= stats.starCount,
                    );
                  }),
                  const SizedBox(width: 6),
                  Text(
                    stats.ratingLabel,
                    style: AppTextStyles.body.copyWith(color: AppColors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${stats.ridesCountLabel})',
                    style: AppTextStyles.small.copyWith(color: AppColors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeaderActionCircle(icon: Icons.call_outlined, onTap: onCallPassenger),
        const SizedBox(width: 8),
        _HeaderActionCircle(
          iconWidget: const FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 18,
            color: AppColors.primaryDark,
          ),
          onTap: onOpenPassengerWhatsApp,
        ),
      ],
    );
  }
}

class _PassengerAvatar extends StatelessWidget {
  const _PassengerAvatar({
    required this.photoUrl,
    required this.size,
    required this.iconSize,
  });

  final String? photoUrl;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = Env.resolveProfilePhotoUrl(photoUrl);
    return Container(
      height: size,
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AppColors.goldGradient,
        shape: BoxShape.circle,
      ),
      child: resolvedUrl == null
          ? Icon(Icons.person_outline_rounded, size: iconSize)
          : Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.person_outline_rounded, size: iconSize),
            ),
    );
  }
}

class _HeaderActionCircle extends StatelessWidget {
  const _HeaderActionCircle({this.icon, this.iconWidget, required this.onTap})
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
          boxShadow: const <BoxShadow>[
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

class _StarIcon extends StatelessWidget {
  const _StarIcon({this.isEmpty = false});

  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      size: 16,
      color: isEmpty ? const Color(0xFFD8D8D8) : const Color(0xFFBE8A10),
    );
  }
}
