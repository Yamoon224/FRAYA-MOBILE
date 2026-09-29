library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

/// Conteneur de dialog custom Fraya — remplace AlertDialog pour tous les modals.
///
/// Fournit le fond blanc avec ombres, coins arrondis et contrainte responsive.
class FrayaDialog extends StatelessWidget {
  const FrayaDialog({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final hPad = context.responsiveValue<double>(
      compact: 16,
      phone: 20,
      largePhone: 24,
      tablet: 32,
    );
    final maxWidth = context.responsiveValue<double>(
      compact: double.infinity,
      phone: double.infinity,
      largePhone: 480,
      tablet: 520,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
            boxShadow: AppColors.shadowLg,
          ),
          child: Padding(
            padding:
                padding ??
                EdgeInsets.fromLTRB(hPad, 32, hPad, 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Icône centrée dans deux cercles concentriques colorés.
///
/// Utilisé en haut de chaque dialog pour identifier visuellement le type.
class FrayaDialogIcon extends StatelessWidget {
  const FrayaDialogIcon({
    super.key,
    required this.icon,
    required this.color,
    this.outerSize = 72,
    this.innerSize = 52,
    this.iconSize = 28,
  });

  final IconData icon;
  final Color color;
  final double outerSize;
  final double innerSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}
