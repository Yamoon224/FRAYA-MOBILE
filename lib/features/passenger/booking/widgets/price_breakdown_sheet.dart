import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/extensions.dart';

/// Ligne cliquable qui ouvre un modal de décomposition du tarif.
class PriceBreakdownTrigger extends StatelessWidget {
  const PriceBreakdownTrigger({
    super.key,
    required this.totalPrice,
    required this.basePrice,
    required this.distancePrice,
    required this.durationPrice,
    required this.distanceText,
    required this.durationText,
  });

  final int totalPrice;
  final int basePrice;
  final int distancePrice;
  final int durationPrice;
  final String distanceText;
  final String durationText;

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PriceBreakdownSheet(
        basePrice: basePrice,
        distancePrice: distancePrice,
        durationPrice: durationPrice,
        totalPrice: totalPrice,
        distanceText: distanceText,
        durationText: durationText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _show(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Voir la décomposition du tarif',
                style: AppTextStyles.small.copyWith(color: AppColors.warning),
              ),
            ),
            Text(
              '${AppDateUtils.formatPrice(totalPrice)} FCFA',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.warning, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PriceBreakdownSheet extends StatelessWidget {
  const _PriceBreakdownSheet({
    required this.basePrice,
    required this.distancePrice,
    required this.durationPrice,
    required this.totalPrice,
    required this.distanceText,
    required this.durationText,
  });

  final int basePrice;
  final int distancePrice;
  final int durationPrice;
  final int totalPrice;
  final String distanceText;
  final String durationText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Décomposition du tarif',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Le prix est calculé selon trois composantes :',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 16),
          _Row('Prix de base', 'Forfait de prise en charge', basePrice),
          const SizedBox(height: 12),
          _Row('Distance ($distanceText)', 'Tarif kilométrique parcouru', distancePrice),
          const SizedBox(height: 12),
          _Row('Durée ($durationText)', 'Temps estimé du trajet', durationPrice),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '${AppDateUtils.formatPrice(totalPrice)} FCFA',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.sublabel, this.price);

  final String label;
  final String sublabel;
  final int price;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.body),
              Text(sublabel, style: AppTextStyles.xs),
            ],
          ),
        ),
        Text(
          '${AppDateUtils.formatPrice(price)} FCFA',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
