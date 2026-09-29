import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/models/places_models.dart';
import '../../../../../shared/providers/saved_places_provider.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/dashed_rect_painter.dart';
import '../../screens/address_pin_picker_screen.dart';
import 'simple_search_sheet.dart';
import 'custom_saved_place_dialog.dart';

class AddPlaceButton extends ConsumerWidget {
  const AddPlaceButton({super.key});

  Future<void> _handleSelection(BuildContext context, WidgetRef ref) async {
    // 1. Ouvrir la recherche de lieu
    final PlaceDetails? place = await showModalBottomSheet<PlaceDetails>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SimpleSearchSheet(),
    );

    if (place == null || !context.mounted) return;

    // 2. Ajuster la position sur carte
    final precisePlace = await Navigator.of(context).push<PlaceDetails>(
      MaterialPageRoute(
        builder: (_) => AddressPinPickerScreen(initialPlace: place),
      ),
    );

    if (precisePlace == null || !context.mounted) return;

    // 3. Choisir le type
    final type = await showDialog<SavedAddressType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer comme...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.home_rounded,
                color: AppColors.primaryDark,
              ),
              title: const Text('Maison'),
              onTap: () => Navigator.pop(context, SavedAddressType.home),
            ),
            ListTile(
              leading: const Icon(
                Icons.work_rounded,
                color: AppColors.primaryDark,
              ),
              title: const Text('Travail'),
              onTap: () => Navigator.pop(context, SavedAddressType.work),
            ),
            ListTile(
              leading: const Icon(
                Icons.star_rounded,
                color: AppColors.primaryDark,
              ),
              title: const Text('Autre'),
              onTap: () => Navigator.pop(context, SavedAddressType.custom),
            ),
          ],
        ),
      ),
    );

    if (type == null || !context.mounted) return;

    // 4. Sauvegarder
    String label;
    String? iconKey;
    if (type == SavedAddressType.home) {
      label = 'Maison';
    } else if (type == SavedAddressType.work) {
      label = 'Travail';
    } else {
      final customConfig = await showDialog<CustomSavedPlaceConfig>(
        context: context,
        builder: (context) =>
            CustomSavedPlaceDialog(initialLabel: precisePlace.name),
      );
      if (customConfig == null || !context.mounted) return;
      label = customConfig.label;
      iconKey = customConfig.iconKey;
    }

    final address = SavedAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      type: type,
      place: precisePlace,
      iconKey: iconKey,
    );

    await ref.read(savedPlacesNotifierProvider.notifier).save(address);

    if (context.mounted) {
      AppSnackBar.showSuccess(context, 'Lieu enregistré avec succès');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: InkWell(
        onTap: () => _handleSelection(context, ref),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: CustomPaint(
          painter: DashedRectPainter(
            color: context.colors.greyLight,
            strokeWidth: 1,
            gap: 4,
            radius: AppTheme.radiusLg,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: context.colors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ajouter un lieu',
                  style: AppTextStyles.body.copyWith(
                    color: context.colors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
