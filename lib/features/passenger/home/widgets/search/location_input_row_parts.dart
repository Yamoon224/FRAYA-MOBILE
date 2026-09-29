import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../../core/theme/app_colors.dart';
import '/../../../../core/theme/app_theme.dart';
import '/../../../../shared/providers/places_provider.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import '/../../../../../core/models/places_models.dart';
import '../../providers/destination_search_controller.dart';

const kLocationInputTrailingSlotSize = AppTheme.touchTargetMin;

Widget buildLocationInputTrailingAction({
  required BuildContext context,
  required WidgetRef ref,
  required bool showClearIcon,
  required bool showDestinationConfirm,
  required bool showPickupRestore,
  required PlaceDetails? selectedDestination,
  required SearchType searchType,
  required VoidCallback onClear,
  required VoidCallback onPickupRestore,
}) {
  if (showClearIcon) {
    return SearchFieldTrailingSlot(
      size: kLocationInputTrailingSlotSize,
      child: SearchFieldClearButton(
        tooltip: 'Vider le champ',
        onPressed: onClear,
      ),
    );
  }
  if (showDestinationConfirm) {
    return SearchFieldTrailingSlot(
      size: kLocationInputTrailingSlotSize,
      child: SearchFieldIconButton(
        tooltip: 'Confirmer la destination',
        icon: Icons.arrow_forward_rounded,
        iconColor: AppColors.primary,
        onPressed: () => ref
            .read(destinationSearchControllerProvider.notifier)
            .handleDirectPlaceSelection(
              context,
              selectedDestination!,
              searchType,
            ),
      ),
    );
  }
  if (showPickupRestore) {
    return SearchFieldTrailingSlot(
      size: kLocationInputTrailingSlotSize,
      child: SearchFieldIconButton(
        tooltip: 'Ma position actuelle',
        icon: Icons.my_location,
        iconColor: AppColors.primary,
        onPressed: onPickupRestore,
      ),
    );
  }
  return const SearchFieldTrailingSlot(size: kLocationInputTrailingSlotSize);
}

class LocationInputIndicator extends StatelessWidget {
  const LocationInputIndicator({
    super.key,
    required this.color,
    this.isCircle = false,
  });

  final Color color;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: isCircle ? Colors.transparent : color,
          shape: BoxShape.circle,
          border: isCircle ? Border.all(color: color, width: 2) : null,
        ),
      ),
    );
  }
}

class SearchFieldTrailingSlot extends StatelessWidget {
  const SearchFieldTrailingSlot({super.key, this.child, required this.size});

  final Widget? child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Align(
        alignment: Alignment.centerRight,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class SearchFieldIconButton extends StatelessWidget {
  const SearchFieldIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
    this.size = 32,
  });

  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: size, height: size),
        splashRadius: size / 2,
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

class SearchFieldClearButton extends StatelessWidget {
  const SearchFieldClearButton({
    super.key,
    required this.tooltip,
    this.onPressed,
  });

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: context.colors.surfacePressed,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.greyLight),
              boxShadow: AppColors.shadowSm,
            ),
            child: Icon(
              Icons.close_rounded,
              color: context.colors.textSecondary,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}
