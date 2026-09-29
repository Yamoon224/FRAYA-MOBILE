import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';

class FrayaBottomSheetContainer extends StatelessWidget {
  const FrayaBottomSheetContainer({
    super.key,
    required this.header,
    required this.body,
    this.footer,
    this.maxHeightFactor = 0.84,
  });

  final Widget header;
  final Widget body;
  final Widget? footer;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final surfaceColor = context.colors.surface;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * maxHeightFactor,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radius2xl),
              ),
              boxShadow: AppColors.shadowLg,
            ),
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingLg,
              AppTheme.spacingLg,
              AppTheme.spacingLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: AppTheme.spacingLg),
                Expanded(child: SingleChildScrollView(child: body)),
                if (footer != null) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
