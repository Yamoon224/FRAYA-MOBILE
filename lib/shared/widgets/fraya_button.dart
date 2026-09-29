/// Bouton premium Fraya Taxi.
///
/// Implémente les variantes du Design System v3.1 :
/// - **primary** : Dégradé jaune, texte noir, ombre jaune
/// - **secondary** : Noir, texte blanc
/// - **outline** : Bordure jaune, transparent
/// - **ghost** : Transparent, texte noir
/// - **danger** : Rouge, texte blanc
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

enum FrayaButtonVariant { primary, secondary, outline, ghost, danger }

enum FrayaButtonSize { sm, md, lg }

class FrayaButton extends StatefulWidget {
  const FrayaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FrayaButtonVariant.primary,
    this.size = FrayaButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leftIcon,
    this.rightIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final FrayaButtonVariant variant;
  final FrayaButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leftIcon;
  final IconData? rightIcon;

  @override
  State<FrayaButton> createState() => _FrayaButtonState();
}

class _FrayaButtonState extends State<FrayaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _resolveHeight(BuildContext context) => switch (widget.size) {
    FrayaButtonSize.sm => context.responsiveValue<double>(
      compact: AppTheme.touchTargetMin,
      phone: AppTheme.touchTargetMin,
      largePhone: AppTheme.touchTargetMd,
      tablet: 52,
    ),
    FrayaButtonSize.md => context.responsiveValue<double>(
      compact: AppTheme.touchTargetMd,
      phone: AppTheme.touchTargetMd,
      largePhone: 52,
      tablet: 56,
    ),
    FrayaButtonSize.lg => context.responsiveValue<double>(
      compact: 52,
      phone: 56,
      largePhone: 56,
      tablet: 60,
    ),
  };

  EdgeInsets _padding(BuildContext context) => switch (widget.size) {
    FrayaButtonSize.sm => EdgeInsets.symmetric(
      horizontal: context.responsiveValue<double>(
        compact: 12,
        phone: 14,
        largePhone: 16,
        tablet: 18,
      ),
      vertical: 8,
    ),
    FrayaButtonSize.md => EdgeInsets.symmetric(
      horizontal: context.responsiveValue<double>(
        compact: 16,
        phone: 18,
        largePhone: 22,
        tablet: 24,
      ),
      vertical: 12,
    ),
    FrayaButtonSize.lg => EdgeInsets.symmetric(
      horizontal: context.responsiveValue<double>(
        compact: 20,
        phone: 24,
        largePhone: 28,
        tablet: 32,
      ),
      vertical: 16,
    ),
  };

  TextStyle get _textStyle => switch (widget.size) {
    FrayaButtonSize.sm => AppTextStyles.buttonSmall,
    FrayaButtonSize.md => AppTextStyles.button,
    FrayaButtonSize.lg => AppTextStyles.buttonLarge,
  };

  Color _textColor(BuildContext context) {
    if (widget.onPressed == null) {
      return Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTextTertiary
          : AppColors.grey;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (widget.variant) {
      FrayaButtonVariant.primary => AppColors.textPrimary,
      FrayaButtonVariant.secondary => Colors.white,
      FrayaButtonVariant.outline =>
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      FrayaButtonVariant.ghost =>
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      FrayaButtonVariant.danger => Colors.white,
    };
  }

  Color get _backgroundColor => switch (widget.variant) {
    FrayaButtonVariant.primary => AppColors.primary,
    FrayaButtonVariant.secondary => AppColors.textPrimary,
    FrayaButtonVariant.outline => Colors.transparent,
    FrayaButtonVariant.ghost => Colors.transparent,
    FrayaButtonVariant.danger => AppColors.error,
  };

  BoxDecoration _decoration(BuildContext context) {
    final isUnavailable = widget.onPressed == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isUnavailable) {
      return BoxDecoration(
        color: isDark ? AppColors.darkSurfacePressed : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: widget.variant == FrayaButtonVariant.outline
            ? Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade400,
                width: 1.5,
              )
            : null,
      );
    }

    if (widget.variant == FrayaButtonVariant.primary && !isUnavailable) {
      return BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppColors.shadowYellowSm,
      );
    }

    return BoxDecoration(
      color: _backgroundColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: widget.variant == FrayaButtonVariant.outline
          ? Border.all(
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
              width: 1.5,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final textColor = _textColor(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _controller.forward(),
        onTapUp: isDisabled
            ? null
            : (_) {
                _controller.reverse();
                widget.onPressed?.call();
              },
        onTapCancel: isDisabled ? null : () => _controller.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(minHeight: _resolveHeight(context)),
          width: widget.isFullWidth ? double.infinity : null,
          padding: _padding(context),
          decoration: _decoration(context),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisSize: widget.isFullWidth
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.leftIcon != null) ...[
                        Icon(
                          widget.leftIcon,
                          size: context.responsiveValue<double>(
                            compact: 18,
                            phone: 18,
                            largePhone: 20,
                            tablet: 20,
                          ),
                          color: textColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _textStyle.copyWith(color: textColor),
                        ),
                      ),
                      if (widget.rightIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          widget.rightIcon,
                          size: context.responsiveValue<double>(
                            compact: 18,
                            phone: 18,
                            largePhone: 20,
                            tablet: 20,
                          ),
                          color: textColor,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
