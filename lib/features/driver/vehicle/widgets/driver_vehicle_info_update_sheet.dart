library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../providers/driver_vehicle_info_update_provider.dart';
import 'driver_vehicle_info_section.dart';

class DriverVehicleInfoUpdateSheet extends ConsumerStatefulWidget {
  const DriverVehicleInfoUpdateSheet({
    super.key,
    this.vehicleId,
    this.title = 'Infos vehicule',
    this.description =
        'Modifiez les informations descriptives du vehicule. Une validation admin sera relancee.',
  });

  final int? vehicleId;
  final String title;
  final String description;

  @override
  ConsumerState<DriverVehicleInfoUpdateSheet> createState() =>
      _DriverVehicleInfoUpdateSheetState();
}

class _DriverVehicleInfoUpdateSheetState
    extends ConsumerState<DriverVehicleInfoUpdateSheet> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(driverVehicleInfoUpdateProvider.notifier)
          .prefillFromSession(vehicleId: widget.vehicleId);
    });
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DriverVehicleInfoUpdateState>(driverVehicleInfoUpdateProvider, (
      _,
      next,
    ) {
      if (!mounted) return;
      if (next.success) {
        ref.read(driverVehicleInfoUpdateProvider.notifier).clearFeedback();
        Navigator.of(context).pop(true);
      } else if (next.errorMessage != null) {
        ref.read(driverVehicleInfoUpdateProvider.notifier).clearFeedback();
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });

    final state = ref.watch(driverVehicleInfoUpdateProvider);
    _syncControllers(state);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(widget.title, style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: AppTextStyles.small.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DriverVehicleInfoSection(
                    brandController: _brandController,
                    modelController: _modelController,
                    yearController: _yearController,
                    colorController: _colorController,
                    licensePlateController: _licensePlateController,
                    selectedRange: state.selectedRange,
                    airConditioning: state.airConditioning,
                    enabled: !state.isSubmitting,
                    onBrandChanged: ref
                        .read(driverVehicleInfoUpdateProvider.notifier)
                        .setBrand,
                    onModelChanged: ref
                        .read(driverVehicleInfoUpdateProvider.notifier)
                        .setModel,
                    onYearChanged: ref
                        .read(driverVehicleInfoUpdateProvider.notifier)
                        .setYear,
                    onColorChanged: ref
                        .read(driverVehicleInfoUpdateProvider.notifier)
                        .setColor,
                    onLicensePlateChanged: ref
                        .read(driverVehicleInfoUpdateProvider.notifier)
                        .setLicensePlate,
                    onRangeChanged: ref
                        .read(driverVehicleInfoUpdateProvider.notifier)
                        .setRange,
                    onAirConditioningChanged: ref
                        .read(driverVehicleInfoUpdateProvider.notifier)
                        .setAirConditioning,
                  ),
                  const SizedBox(height: 20),
                  FrayaButton(
                    label: state.isSubmitting
                        ? 'Mise a jour...'
                        : 'Confirmer la mise a jour',
                    isLoading: state.isSubmitting,
                    onPressed: state.canSubmit
                        ? ref
                              .read(driverVehicleInfoUpdateProvider.notifier)
                              .submit
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        'Annuler',
                        style: AppTextStyles.h2.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncControllers(DriverVehicleInfoUpdateState state) {
    _syncController(_brandController, state.brand);
    _syncController(_modelController, state.model);
    _syncController(_yearController, state.year);
    _syncController(_colorController, state.color);
    _syncController(_licensePlateController, state.licensePlate);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.greyLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
