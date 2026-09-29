library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';

class DriverHomeTopBar extends StatelessWidget {
  const DriverHomeTopBar({
    super.key,
    required this.isOnline,
    required this.isBusy,
    required this.canToggleOnline,
    required this.showStatusToggle,
    required this.onToggleOnline,
    required this.onMenuPressed,
    required this.onMoneyPressed,
    required this.onNavigationPressed,
    this.onBackToHome,
    this.isNavigationEnabled = true,
  });

  final bool isOnline;
  final bool isBusy;
  final bool canToggleOnline;
  final bool showStatusToggle;
  final ValueChanged<bool> onToggleOnline;
  final VoidCallback onMenuPressed;
  final VoidCallback onMoneyPressed;
  final VoidCallback? onNavigationPressed;
  final VoidCallback? onBackToHome;
  final bool isNavigationEnabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusPillHeight = context.responsiveValue<double>(
      compact: 40,
      phone: 48,
      largePhone: 48,
      tablet: 52,
    );
    final floatingButtonSize = context.responsiveValue<double>(
      compact: 40,
      phone: AppTheme.floatingButtonSm,
      largePhone: AppTheme.touchTargetMd,
      tablet: 50,
    );
    final horizontalGap = context.responsiveValue<double>(
      compact: AppTheme.spacingSm,
      phone: AppTheme.spacingSm,
      largePhone: AppTheme.spacingMd,
      tablet: AppTheme.spacingMd,
    );
    final switchWidth = context.responsiveValue<double>(
      compact: 42,
      phone: 46,
      largePhone: 48,
      tablet: 50,
    );
    final switchHeight = context.responsiveValue<double>(
      compact: 26,
      phone: 28,
      largePhone: 30,
      tablet: 30,
    );
    final statusFontSize = context.responsiveValue<double>(
      compact: 12.5,
      phone: 13,
      largePhone: 13.5,
      tablet: 14,
    );
    final pillHorizontalPadding = context.responsiveValue<double>(
      compact: 8,
      phone: 10,
      largePhone: 12,
      tablet: 14,
    );

    if (!showStatusToggle) {
      return Row(
        children: [
          _FloatingCircleButton(
            icon: Icons.arrow_back_rounded,
            onPressed: onBackToHome,
            size: floatingButtonSize,
          ),
          const Spacer(),
          _FloatingCircleButton(
            icon: Icons.navigation_rounded,
            gradient: isNavigationEnabled
                ? AppColors.primaryGradient
                : const LinearGradient(
                    colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                  ),
            iconColor: isNavigationEnabled
                ? AppColors.primaryDark
                : const Color(0xFF9CA3AF),
            onPressed: onNavigationPressed,
            size: floatingButtonSize,
          ),
        ],
      );
    }

    return Row(
      children: [
        _FloatingCircleButton(
          icon: Icons.menu_rounded,
          onPressed: onMenuPressed,
          size: floatingButtonSize,
        ),
        SizedBox(width: horizontalGap),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final preferredWidth = context.responsiveValue<double>(
                compact: 190,
                phone: 212,
                largePhone: 228,
                tablet: 248,
              );

              return Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth
                        .clamp(0.0, preferredWidth)
                        .toDouble(),
                  ),
                  child: Container(
                    height: statusPillHeight,
                    padding: EdgeInsets.symmetric(
                      horizontal: pillHorizontalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.success
                          : context.colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDark ? null : AppColors.shadowMd,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: switchWidth,
                          height: switchHeight,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: CupertinoSwitch(
                              value: isOnline,
                              activeTrackColor: const Color(0xFF44CB85),
                              inactiveTrackColor: AppColors.error,
                              thumbColor: Colors.white,
                              onChanged: isBusy || !canToggleOnline
                                  ? null
                                  : onToggleOnline,
                            ),
                          ),
                        ),
                        SizedBox(width: horizontalGap),
                        Expanded(
                          child: Text(
                            isOnline ? 'En ligne' : 'Hors ligne',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: isOnline
                                  ? Colors.white
                                  : context.colors.textPrimary,
                              fontSize: statusFontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(width: horizontalGap),
        _FloatingCircleButton(
          icon: Icons.attach_money_rounded,
          gradient: AppColors.primaryGradient,
          iconColor: AppColors.primaryDark,
          onPressed: onMoneyPressed,
          size: floatingButtonSize,
        ),
      ],
    );
  }
}

class DriverHomeFloatingStatusBadge extends StatelessWidget {
  const DriverHomeFloatingStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : AppColors.shadowMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 9,
            width: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.buttonSmall.copyWith(
                color: context.colors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.iconColor = AppColors.textPrimary,
    this.size = AppTheme.floatingButtonSm,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gradient == null ? context.colors.surface : null,
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: AppColors.shadowMd,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: iconColor == AppColors.textPrimary ? context.colors.textPrimary : iconColor, size: 22),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
