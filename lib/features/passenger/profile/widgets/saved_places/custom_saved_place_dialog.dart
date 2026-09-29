import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../shared/utils/saved_place_icons.dart';

class CustomSavedPlaceConfig {
  const CustomSavedPlaceConfig({
    required this.label,
    required this.iconKey,
  });

  final String label;
  final String iconKey;
}

class CustomSavedPlaceDialog extends StatefulWidget {
  const CustomSavedPlaceDialog({
    super.key,
    required this.initialLabel,
  });

  final String initialLabel;

  @override
  State<CustomSavedPlaceDialog> createState() => _CustomSavedPlaceDialogState();
}

class _CustomSavedPlaceDialogState extends State<CustomSavedPlaceDialog> {
  late final TextEditingController _labelController;
  String _selectedIconKey = SavedPlaceIcons.star;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurer le lieu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Nom du lieu',
                hintText: 'Ex: Salle de sport',
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            Text('Icône', style: AppTextStyles.small),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SavedPlaceIcons.options.map((option) {
                final selected = option.key == _selectedIconKey;
                return ChoiceChip(
                  label: Text(option.label),
                  selected: selected,
                  avatar: Icon(
                    option.icon,
                    size: 18,
                    color: selected ? Colors.white : context.colors.textSecondary,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedIconKey = option.key;
                    });
                  },
                  selectedColor: AppColors.primaryDark,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : context.colors.textPrimary,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final label = _labelController.text.trim();
            if (label.isEmpty) return;
            Navigator.pop(
              context,
              CustomSavedPlaceConfig(label: label, iconKey: _selectedIconKey),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
