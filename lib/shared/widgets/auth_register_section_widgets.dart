import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/auth_register_draft.dart';

class AuthRegisterSectionSurface extends StatelessWidget {
  const AuthRegisterSectionSurface({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.greyExtraLight;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              subtitle!,
              style: AppTextStyles.small.copyWith(color: subtitleColor),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          ...children,
        ],
      ),
    );
  }
}

class AuthRegisterStepHeader extends StatelessWidget {
  const AuthRegisterStepHeader({super.key, required this.step});

  final AuthRegisterFlowStep step;

  @override
  Widget build(BuildContext context) {
    final activeIndex = AuthRegisterFlowStep.values.indexOf(step);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppColors.darkBorder : AppColors.greyLight;
    return Row(
      children: [
        for (var index = 0; index < AuthRegisterFlowStep.values.length; index++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
              decoration: BoxDecoration(
                color: index <= activeIndex
                    ? AppColors.primaryDark
                    : inactiveColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

String? requiredRegisterField(String? value) {
  return value == null || value.trim().isEmpty ? 'Champ requis' : null;
}

String? validateOptionalRegisterEmail(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
    return 'Email invalide';
  }
  return null;
}
