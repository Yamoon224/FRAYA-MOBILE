import 'package:flutter/material.dart';
import '/../../../../core/theme/app_text_styles.dart';
import '/../../../../core/theme/app_theme.dart';
import '/../../../../core/utils/responsive.dart';

class SearchHeader extends StatelessWidget {
  final VoidCallback onBack;
  const SearchHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.responsiveValue<double>(
      compact: AppTheme.spacingMd,
      phone: AppTheme.spacingLg,
      largePhone: AppTheme.spacingLg,
      tablet: 28,
    );
    final verticalPadding = context.responsiveValue<double>(
      compact: AppTheme.spacingMd,
      phone: AppTheme.spacingLg,
      largePhone: AppTheme.spacingLg,
      tablet: 28,
    );
    final iconSize = context.responsiveValue<double>(
      compact: 22,
      phone: 24,
      largePhone: 24,
      tablet: 26,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: iconSize),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Text('Destination', style: AppTextStyles.h3),
        ],
      ),
    );
  }
}
