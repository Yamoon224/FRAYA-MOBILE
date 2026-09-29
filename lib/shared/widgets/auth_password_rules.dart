import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PasswordRuleItem extends StatelessWidget {
  const PasswordRuleItem({
    super.key,
    required this.label,
    required this.satisfied,
  });

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = satisfied
        ? const Color(0xFF16A34A)
        : isDark
        ? AppColors.darkTextTertiary
        : AppColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.xs.copyWith(color: color)),
        ],
      ),
    );
  }
}

class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PasswordRuleItem(
            label: '8 caractères minimum',
            satisfied: password.length >= 8,
          ),
          PasswordRuleItem(
            label: 'Une lettre majuscule',
            satisfied: password.contains(RegExp(r'[A-Z]')),
          ),
          PasswordRuleItem(
            label: 'Une lettre minuscule',
            satisfied: password.contains(RegExp(r'[a-z]')),
          ),
          PasswordRuleItem(
            label: 'Un chiffre',
            satisfied: password.contains(RegExp(r'\d')),
          ),
        ],
      ),
    );
  }
}
