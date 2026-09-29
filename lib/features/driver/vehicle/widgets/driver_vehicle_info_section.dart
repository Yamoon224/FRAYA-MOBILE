library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fraya_text_field.dart';
import 'driver_vehicle_range_selector.dart';

class DriverVehicleInfoSection extends StatelessWidget {
  const DriverVehicleInfoSection({
    super.key,
    required this.brandController,
    required this.modelController,
    required this.yearController,
    required this.colorController,
    required this.licensePlateController,
    required this.selectedRange,
    required this.airConditioning,
    required this.enabled,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onYearChanged,
    required this.onColorChanged,
    required this.onLicensePlateChanged,
    required this.onRangeChanged,
    required this.onAirConditioningChanged,
  });

  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController colorController;
  final TextEditingController licensePlateController;
  final String selectedRange;
  final bool airConditioning;
  final bool enabled;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onLicensePlateChanged;
  final ValueChanged<String> onRangeChanged;
  final ValueChanged<bool> onAirConditioningChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FrayaTextField(
          controller: brandController,
          label: 'Marque',
          hint: 'Ex: Toyota',
          enabled: enabled,
          onChanged: onBrandChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        FrayaTextField(
          controller: modelController,
          label: 'Modèle',
          hint: 'Ex: Corolla',
          enabled: enabled,
          onChanged: onModelChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: FrayaTextField(
                controller: yearController,
                label: 'Annee',
                hint: '2022',
                enabled: enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: onYearChanged,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: FrayaTextField(
                controller: colorController,
                label: 'Couleur',
                hint: 'Rouge',
                enabled: enabled,
                onChanged: onColorChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        FrayaTextField(
          controller: licensePlateController,
          label: 'Plaque d immatriculation',
          hint: '12ERSTDFD',
          enabled: enabled,
          onChanged: onLicensePlateChanged,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        DriverVehicleRangeSelector(
          selectedRange: selectedRange,
          enabled: enabled,
          onSelected: onRangeChanged,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        SwitchListTile(
          value: airConditioning,
          onChanged: enabled ? onAirConditioningChanged : null,
          title: const Text('Climatisation'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
