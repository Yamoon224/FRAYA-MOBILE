import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/providers/location_provider.dart';

class HomeAddressPill extends ConsumerWidget {
  const HomeAddressPill({super.key, this.addressText});

  final String? addressText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String formattedAddress =
        addressText ?? ref.watch(formattedAddressProvider);
    final horizontalPadding = context.responsiveValue<double>(
      compact: 12,
      phone: 16,
      largePhone: 18,
      tablet: 20,
    );
    final verticalPadding = context.responsiveValue<double>(
      compact: 8,
      phone: 10,
      largePhone: 11,
      tablet: 12,
    );
    final iconSize = context.responsiveValue<double>(
      compact: 16,
      phone: 18,
      largePhone: 18,
      tablet: 20,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: iconSize,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formattedAddress,
              style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
