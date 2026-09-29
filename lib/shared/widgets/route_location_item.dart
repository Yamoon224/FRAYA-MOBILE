import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

class RouteLocationItem extends StatelessWidget {
  const RouteLocationItem({
    super.key,
    required this.label,
    required this.location,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  final String label;
  final String location;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final iconContainerSize = context.responsiveValue<double>(
      compact: 34,
      phone: 36,
      largePhone: 38,
      tablet: 40,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: iconContainerSize,
          width: iconContainerSize,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: iconContainerSize * 0.5, color: iconColor),
        ),
        SizedBox(
          width: context.responsiveValue<double>(
            compact: 10,
            phone: 12,
            largePhone: 12,
            tablet: 14,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textSmall.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h1.copyWith(
                  fontSize: context.responsiveValue<double>(
                    compact: 14,
                    phone: 15,
                    largePhone: 15,
                    tablet: 16,
                  ),
                  color: const Color(0xFF222222),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
