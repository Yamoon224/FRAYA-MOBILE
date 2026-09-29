import 'package:flutter/material.dart';
import '/../../../../core/theme/app_colors.dart';
import '/../../../../core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';

class PlaceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? distance;
  final VoidCallback onTap;

  const PlaceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
      ),
      trailing: distance != null
          ? Text(
              distance!,
              style: AppTextStyles.xs.copyWith(color: context.colors.textTertiary),
            )
          : null,
      onTap: onTap,
    );
  }
}
