library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';

class DriverHomePrimaryRideActionButton extends StatelessWidget {
  const DriverHomePrimaryRideActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isDisabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.7 : 1,
      child: GestureDetector(
        onTap: isDisabled ? null : () => onTap(),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFC89A3B),
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.shadowYellowSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: const Color(0xFF131313),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverHomeCancelRideTextAction extends StatelessWidget {
  const DriverHomeCancelRideTextAction({
    super.key,
    required this.isDisabled,
    required this.onTap,
  });

  final bool isDisabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: isDisabled ? null : () => onTap(),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'Annuler la course',
            style: AppTextStyles.h4.copyWith(
              color: isDisabled
                  ? context.colors.textTertiary
                  : context.colors.textPrimary,
              fontSize: 15.5,
            ),
          ),
        ),
      ),
    );
  }
}
