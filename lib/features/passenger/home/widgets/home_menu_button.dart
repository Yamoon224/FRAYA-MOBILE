import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';

class HomeMenuButton extends StatelessWidget {
  const HomeMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonSize = context.responsiveValue<double>(
      compact: 40,
      phone: 44,
      largePhone: 46,
      tablet: 50,
    );
    final iconSize = context.responsiveValue<double>(
      compact: 20,
      phone: 22,
      largePhone: 22,
      tablet: 24,
    );

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
          boxShadow: AppColors.shadowMd,
        ),
        child: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu, size: iconSize),
              padding: EdgeInsets.zero,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
    );
  }
}
