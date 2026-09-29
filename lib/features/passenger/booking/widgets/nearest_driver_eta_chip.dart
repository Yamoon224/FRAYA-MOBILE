import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/nearest_driver_eta_provider.dart';

class NearestDriverEtaChip extends ConsumerWidget {
  const NearestDriverEtaChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(nearestDriverEtaMinutesProvider);
    if (minutes == null) return const SizedBox.shrink();

    final Color bgColor;
    final Color textColor;
    if (minutes <= 3) {
      bgColor = context.colors.successBackground;
      textColor = AppColors.successText;
    } else if (minutes <= 7) {
      bgColor = context.colors.isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
      textColor = context.colors.isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
    } else {
      bgColor = context.colors.greyExtraLight;
      textColor = context.colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 11, color: textColor),
          const SizedBox(width: 3),
          Text(
            '~$minutes min',
            style: AppTextStyles.xs.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
