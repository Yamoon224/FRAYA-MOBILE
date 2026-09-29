import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../../core/theme/app_colors.dart';
import '/../../../../core/theme/app_theme.dart';
import '/../../../../core/utils/extensions.dart';
import '/../../../../core/utils/responsive.dart';
import '/../../../../shared/providers/places_provider.dart';
import 'location_input_row.dart';

class LocationInputs extends ConsumerWidget {
  const LocationInputs({
    super.key,
    required this.currentAddress,
    this.isLoading = false,
  });

  final String currentAddress;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPickup = ref.watch(selectedPickupProvider);
    final selectedDestination = ref.watch(selectedDestinationProvider);
    final horizontalPadding = context.responsiveValue<double>(
      compact: AppTheme.spacingMd,
      phone: AppTheme.spacingLg,
      largePhone: AppTheme.spacingLg,
      tablet: 28,
    );
    final bottomPadding = context.responsiveValue<double>(
      compact: AppTheme.spacingMd,
      phone: AppTheme.spacingLg,
      largePhone: AppTheme.spacingLg,
      tablet: 28,
    );
    final rowGap = context.responsiveValue<double>(
      compact: 20,
      phone: 24,
      largePhone: 24,
      tablet: 28,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        bottomPadding,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 25,
            bottom: 25,
            child: Container(width: 1, color: context.colors.greyLight),
          ),
          Column(
            children: [
              LocationInputRow(
                label: 'Prise en charge',
                value: selectedPickup?.address ?? currentAddress,
                isCustom: selectedPickup != null,
                color: AppColors.success,
                type: SearchType.pickup,
                hint: 'D\'ou partez-vous ?',
                isLoading: isLoading && selectedPickup == null,
              ),
              SizedBox(height: rowGap),
              LocationInputRow(
                label: 'Destination',
                value: selectedDestination?.name,
                color: const Color(0xFFD4A843),
                isCircle: true,
                type: SearchType.destination,
                hint: 'Ou allez-vous ?',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
