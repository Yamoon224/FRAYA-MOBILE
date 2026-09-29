import 'package:flutter/material.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/features/passenger/history/details/widgets/ride_receipt_sheet.dart';

class RideDetailsHeader extends StatelessWidget implements PreferredSizeWidget {
  final Ride ride;
  const RideDetailsHeader({super.key, required this.ride});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.colors.surface;
    final textColor = context.colors.textPrimary;
    final secondaryTextColor = context.colors.textSecondary;
    final receiptBackground = context.colors.isDark
        ? context.colors.surfaceElevated
        : const Color(0xFFFBF6E9);

    return AppBar(
      backgroundColor: surfaceColor,
      foregroundColor: textColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la course',
            style: AppTextStyles.h4.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Course ${ride.keyRide ?? ride.id}',
            style: AppTextStyles.xs.copyWith(color: secondaryTextColor),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppTheme.spacingMd),
          child: TextButton(
            onPressed: () => RideReceiptSheet.show(context, ride),
            style: TextButton.styleFrom(
              backgroundColor: receiptBackground,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: Text(
              'Voir reçu',
              style: AppTextStyles.buttonSmall.copyWith(
                color: const Color(0xFFD4A843),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
