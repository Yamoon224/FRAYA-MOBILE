import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/extensions.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';

class StatusHeader extends StatelessWidget {
  const StatusHeader({super.key, required this.status});
  final RideStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          status.title,
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          status.subtitle,
          style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
