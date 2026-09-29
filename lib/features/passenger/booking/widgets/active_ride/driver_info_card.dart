import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:fraya_mobile/domain/models/active_ride.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/passenger_contact_provider.dart';

class DriverInfoCard extends ConsumerWidget {
  const DriverInfoCard({super.key, required this.ride});

  final ActiveRide ride;

  Widget _driverPhoto(String photo) {
    const fallback = 'assets/images/driver_placeholder.png';
    final resolvedPhoto = _resolvePhotoUrl(photo);
    if (resolvedPhoto != null) {
      return Image.network(
        resolvedPhoto,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, _) => const _DriverPhotoPlaceholder(),
      );
    }
    if (photo.trim().isEmpty || photo == fallback) {
      return const _DriverPhotoPlaceholder();
    }
    return Image.asset(photo, width: 60, height: 60, fit: BoxFit.cover);
  }

  String? _resolvePhotoUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('assets/')) return null;
    return Env.resolveProfilePhotoUrl(trimmed);
  }

  Future<void> _handleCallDriver(BuildContext context, WidgetRef ref) async {
    final opened = await ref
        .read(passengerContactControllerProvider)
        .callDriver(ride);
    if (!context.mounted) return;
    if (!opened) {
      AppSnackBar.showError(
        context,
        'Numéro du chauffeur indisponible pour l\'appel.',
      );
    }
  }

  Future<void> _handleOpenWhatsApp(BuildContext context, WidgetRef ref) async {
    final opened = await ref
        .read(passengerContactControllerProvider)
        .openDriverWhatsApp(ride);
    if (!context.mounted) return;
    if (!opened) {
      AppSnackBar.showError(
        context,
        'Impossible d\'ouvrir WhatsApp sans numéro chauffeur valide.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ClipOval(child: _driverPhoto(ride.driverPhoto)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ride.driverName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _VerifiedChip(),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  const Icon(Icons.star, color: AppColors.primary, size: 14),
                  Text(
                    '${ride.driverRating}',
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '•',
                    style: AppTextStyles.small.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  Text(
                    '${ride.driverRidesCount} courses',
                    style: AppTextStyles.small.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderActionCircle(
              icon: Icons.call_outlined,
              onTap: () => _handleCallDriver(context, ref),
            ),
            const SizedBox(width: 8),
            _HeaderActionCircle(
              iconWidget: const FaIcon(
                FontAwesomeIcons.whatsapp,
                size: 18,
                color: AppColors.primaryDark,
              ),
              onTap: () => _handleOpenWhatsApp(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _DriverPhotoPlaceholder extends StatelessWidget {
  const _DriverPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.greyExtraLight,
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          color: context.colors.textSecondary,
          size: 32,
        ),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: context.colors.isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32), size: 14),
          const SizedBox(width: 4),
          Text(
            'Vérifié',
            style: AppTextStyles.xs.copyWith(
              color: context.colors.isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
