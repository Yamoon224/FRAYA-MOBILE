import 'package:flutter/material.dart';
import '../../../core/utils/extensions.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.greyLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
