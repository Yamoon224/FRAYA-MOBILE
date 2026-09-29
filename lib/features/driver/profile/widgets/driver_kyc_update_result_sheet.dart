library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../shared/widgets/fraya_button.dart';
import '../providers/driver_kyc_update_state.dart';

class DriverKycUpdateResultSheet extends StatelessWidget {
  const DriverKycUpdateResultSheet({super.key, required this.completion});

  final DriverKycUpdateCompletion completion;

  @override
  Widget build(BuildContext context) {
    final presentation = _KycUpdateResultPresentation.fromCompletion(
      completion,
    );
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: presentation.backgroundColor,
              child: Icon(presentation.icon, color: presentation.iconColor),
            ),
            const SizedBox(height: 14),
            Text(presentation.title, style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Text(
              completion.message,
              style: AppTextStyles.body.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            FrayaButton(
              label: 'Compris',
              size: FrayaButtonSize.lg,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _KycUpdateResultPresentation {
  const _KycUpdateResultPresentation({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  factory _KycUpdateResultPresentation.fromCompletion(
    DriverKycUpdateCompletion completion,
  ) {
    if (completion.isApproved) {
      return const _KycUpdateResultPresentation(
        title: 'Documents validés',
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: Color(0xFFDDF7E6),
        iconColor: Color(0xFF0E8B36),
      );
    }
    if (completion.isRejected) {
      return const _KycUpdateResultPresentation(
        title: 'Documents rejetés',
        icon: Icons.error_outline_rounded,
        backgroundColor: Color(0xFFFEE2E2),
        iconColor: Color(0xFFB91C1C),
      );
    }
    return const _KycUpdateResultPresentation(
      title: 'Validation en cours',
      icon: Icons.hourglass_top_rounded,
      backgroundColor: Color(0xFFDBEAFE),
      iconColor: Color(0xFF1D4ED8),
    );
  }
}
