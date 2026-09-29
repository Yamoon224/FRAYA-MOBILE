/// Indicateur de chargement Fraya.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FrayaLoadingIndicator extends StatelessWidget {
  const FrayaLoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.small,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class FrayaLoadingOverlay extends StatelessWidget {
  const FrayaLoadingOverlay({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: FrayaLoadingIndicator(
        message: message,
        size: 48,
      ),
    );
  }
}
