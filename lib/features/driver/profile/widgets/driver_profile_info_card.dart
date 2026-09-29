library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';

class DriverProfileInfoCard extends StatelessWidget {
  const DriverProfileInfoCard({
    super.key,
    required this.phone,
    required this.email,
    required this.memberSince,
  });

  final String phone;
  final String email;
  final String memberSince;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: context.colors.greyLight,
        ),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Telephone',
            value: phone,
          ),
          _DividerLine(),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
          _DividerLine(),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Membre depuis',
            value: memberSince,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = context.colors.textSecondary;
    final valueColor = context.colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.small.copyWith(color: labelColor),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(color: valueColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: context.colors.greyLight,
    );
  }
}
