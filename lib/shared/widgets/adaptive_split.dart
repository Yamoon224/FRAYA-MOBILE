import 'package:flutter/material.dart';

class AdaptiveSplit extends StatelessWidget {
  const AdaptiveSplit({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 360,
    this.spacing = 16,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: left),
            SizedBox(width: spacing),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
