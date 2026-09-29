import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';

class RideStarRatingRow extends StatelessWidget {
  const RideStarRatingRow({
    super.key,
    required this.currentRating,
    required this.onRatingChanged,
    this.activeColor = AppColors.primary,
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.activeIcon = Icons.star,
    this.inactiveIcon = Icons.star_border,
    this.iconSize = 40,
    this.compactIconSize = 34,
    this.tapTargetSize = 44,
    this.compactTapTargetSize = 40,
    this.spacing = AppTheme.spacingXs,
    this.allowClear = true,
  });

  final int currentRating;
  final ValueChanged<int> onRatingChanged;
  final Color activeColor;
  final Color inactiveColor;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final double iconSize;
  final double compactIconSize;
  final double tapTargetSize;
  final double compactTapTargetSize;
  final double spacing;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = maxWidth < 320;
        final resolvedIconSize = isCompact ? compactIconSize : iconSize;
        final resolvedTapTarget = isCompact
            ? compactTapTargetSize
            : tapTargetSize;
        final estimatedRowWidth = (resolvedTapTarget * 5) + (spacing * 4);
        final useWrap = estimatedRowWidth > maxWidth;

        final children = List.generate(5, (index) {
          final starValue = index + 1;
          final isSelected = currentRating >= starValue;
          return IconButton(
            onPressed: () => onRatingChanged(
              allowClear && currentRating == starValue ? 0 : starValue,
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            splashRadius: resolvedTapTarget / 2,
            constraints: BoxConstraints.tightFor(
              width: resolvedTapTarget,
              height: resolvedTapTarget,
            ),
            icon: Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: resolvedIconSize,
            ),
          );
        });

        if (useWrap) {
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: children,
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}
