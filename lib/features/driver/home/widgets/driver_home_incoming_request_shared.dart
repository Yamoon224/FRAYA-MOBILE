library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/fraya_button.dart';

class DismissedRequestState extends StatelessWidget {
  const DismissedRequestState({super.key, required this.onRefresh});

  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetHandle(),
        Text(
          'Demandes ignorees',
          style: AppTextStyles.h1.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Toutes les demandes visibles ont ete masquees localement pour cette session.',
          style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
        ),
        const Spacer(),
        FrayaButton(
          label: 'Actualiser les demandes',
          variant: FrayaButtonVariant.outline,
          leftIcon: Icons.refresh_rounded,
          onPressed: onRefresh == null ? null : () => onRefresh!(),
        ),
      ],
    );
  }
}

class AddressTile extends StatelessWidget {
  const AddressTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32.5,
          height: 32.5,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.small),
              Text(
                value,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MetricCell extends StatelessWidget {
  const MetricCell({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.small, textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            color: valueColor ?? context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class MetricDivider extends StatelessWidget {
  const MetricDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      color: context.colors.border,
    );
  }
}

class VerifiedChip extends StatelessWidget {
  const VerifiedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Verifie',
        style: AppTextStyles.buttonSmall.copyWith(fontSize: 12),
      ),
    );
  }
}

class IncomingActions extends StatelessWidget {
  const IncomingActions({
    super.key,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isBusy;
  final Future<void> Function() onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FrayaButton(
            label: 'Refuser',
            variant: FrayaButtonVariant.danger,
            leftIcon: Icons.close_rounded,
            onPressed: isBusy ? null : onDecline,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: FrayaButton(
            label: 'Accepter',
            isLoading: isBusy,
            leftIcon: Icons.near_me_rounded,
            onPressed: isBusy ? null : () => onAccept(),
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 5,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.greyLight,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
