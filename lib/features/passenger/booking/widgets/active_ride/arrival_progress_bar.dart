import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/extensions.dart';

class ArrivalProgressBar extends StatefulWidget {
  final double progress; // entre 0.0 et 1.0
  final LinearGradient gradient;
  final bool isIndeterminate;

  const ArrivalProgressBar({
    super.key,
    this.progress = 0.6,
    this.gradient = AppColors.goldGradient,
    this.isIndeterminate = false,
  });

  @override
  State<ArrivalProgressBar> createState() => _ArrivalProgressBarState();
}

class _ArrivalProgressBarState extends State<ArrivalProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final progress = widget.progress.clamp(0.0, 1.0);
        final progressWidth = widget.isIndeterminate
            ? fullWidth
            : fullWidth * progress;

        return Stack(
          children: [
            // Background
            Container(
              height: 6,
              width: fullWidth,
              decoration: BoxDecoration(
                color: context.colors.greyLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Progress Bar with Animated Gradient Shimmer
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  height: 6,
                  width: progressWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _animatedGradientColors(),
                      stops: [
                        0.0,
                        (_shimmerAnimation.value).clamp(0.0, 1.0),
                        1.0,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<Color> _animatedGradientColors() {
    final colors = widget.gradient.colors;
    final first = colors.isEmpty ? AppColors.primary : colors.first;
    final middle = colors.length > 1 ? colors[1] : AppColors.primaryDark;
    final last = colors.length > 2 ? colors.last : first;
    return [first, middle, last];
  }
}
