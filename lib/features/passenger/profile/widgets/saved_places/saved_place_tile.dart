import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../shared/providers/places_provider.dart';
import '../../../../../shared/providers/saved_places_provider.dart';
import '../../../../../shared/utils/saved_place_icons.dart';
import '../../../booking/providers/ride_categories_provider.dart';

class SavedPlaceTile extends ConsumerWidget {
  final SavedAddress address;
  final bool isEditMode;

  const SavedPlaceTile({
    super.key,
    required this.address,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData getIcon() {
      switch (address.type) {
        case SavedAddressType.home:
          return Icons.home;
        case SavedAddressType.work:
          return Icons.work;
        case SavedAddressType.custom:
          return SavedPlaceIcons.iconFromKey(address.iconKey);
      }
    }

    return Dismissible(
      key: Key(address.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(savedPlacesNotifierProvider.notifier).remove(address.id);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: isEditMode
            ? null
            : () {
                ref.read(selectedCategoryProvider.notifier).clear();
                if (context.mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                ref
                    .read(selectedDestinationProvider.notifier)
                    .setPlace(address.place);
              },
        child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: 6,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.greyExtraLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIcon(),
                color: const Color(0xFFD4A843),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    address.place.address,
                    style: AppTextStyles.xs.copyWith(
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isEditMode)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () {
                  ref.read(savedPlacesNotifierProvider.notifier).remove(address.id);
                },
              ),
          ],
        ),
      ),
      ),
    );
  }
}
