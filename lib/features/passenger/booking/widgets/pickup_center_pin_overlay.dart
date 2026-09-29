import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class PickupCenterPinOverlay extends StatelessWidget {
  const PickupCenterPinOverlay({
    super.key,
    required this.isDragging,
    this.isDestination = false,
  });

  final bool isDragging;
  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    final color = isDestination ? AppColors.error : AppColors.primary;
    return IgnorePointer(
      child: Center(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          offset: isDragging ? const Offset(0, -0.12) : Offset.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.shadowMd,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Container(
                width: 6,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
