library;

import 'package:flutter/material.dart';

import '../../../../core/models/ride_category.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// Choix facultatif d'une seconde gamme, différente de la gamme principale.
/// Le serveur vérifie l'ancienneté et la climatisation exigées pour cette gamme.
class DriverVehicleSecondaryRangeSelector extends StatelessWidget {
  const DriverVehicleSecondaryRangeSelector({
    super.key,
    required this.primaryRange,
    required this.selectedSecondaryRange,
    required this.enabled,
    required this.onSelected,
  });

  final String primaryRange;
  final String? selectedSecondaryRange;
  final bool enabled;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = RideCategory.defaultCategories
        .where((category) => category.id != primaryRange.toUpperCase())
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seconde gamme (facultatif)', style: AppTextStyles.h4),
        const SizedBox(height: 2),
        Text(
          'Si votre véhicule remplit aussi les critères d\'une autre gamme, vous pouvez la choisir. '
          'Vous pourrez la modifier plus tard.',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: [
            ChoiceChip(
              key: const ValueKey('secondary-range-none'),
              label: const Text('Aucune'),
              selected: selectedSecondaryRange == null,
              onSelected: enabled ? (_) => onSelected(null) : null,
            ),
            for (final category in options)
              ChoiceChip(
                key: ValueKey('secondary-range-${category.id}'),
                label: Text(category.name),
                selected: selectedSecondaryRange == category.id,
                onSelected: enabled ? (_) => onSelected(category.id) : null,
              ),
          ],
        ),
      ],
    );
  }
}
