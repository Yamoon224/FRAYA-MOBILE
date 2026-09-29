library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/driver_vehicle_update.dart';
import '../../../../domain/usecases/driver/vehicle/update_driver_vehicle_usecase.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../auth/providers/driver_submission_review_info.dart';
import 'driver_vehicle_dependencies.dart';
import 'driver_vehicle_info_update_session.dart';

final driverVehicleInfoUpdateProvider =
    NotifierProvider<
      DriverVehicleInfoUpdateNotifier,
      DriverVehicleInfoUpdateState
    >(DriverVehicleInfoUpdateNotifier.new, isAutoDispose: true);

class DriverVehicleInfoUpdateState {
  const DriverVehicleInfoUpdateState({
    this.vehicleId,
    this.sidUserId,
    this.brand = '',
    this.model = '',
    this.year = '',
    this.color = '',
    this.licensePlate = '',
    this.selectedRange = 'MAGIC',
    this.airConditioning = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
  });

  final int? vehicleId;
  final int? sidUserId;
  final String brand;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final String selectedRange;
  final bool airConditioning;
  final bool isSubmitting;
  final String? errorMessage;
  final bool success;

  bool get canSubmit =>
      vehicleId != null &&
      brand.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      year.trim().isNotEmpty &&
      color.trim().isNotEmpty &&
      licensePlate.trim().isNotEmpty &&
      selectedRange.trim().isNotEmpty &&
      !isSubmitting;

  DriverVehicleInfoUpdateState copyWith({
    int? vehicleId,
    int? sidUserId,
    String? brand,
    String? model,
    String? year,
    String? color,
    String? licensePlate,
    String? selectedRange,
    bool? airConditioning,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    bool? success,
  }) {
    return DriverVehicleInfoUpdateState(
      vehicleId: vehicleId ?? this.vehicleId,
      sidUserId: sidUserId ?? this.sidUserId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      selectedRange: selectedRange ?? this.selectedRange,
      airConditioning: airConditioning ?? this.airConditioning,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      success: success ?? this.success,
    );
  }
}

class DriverVehicleInfoUpdateNotifier
    extends Notifier<DriverVehicleInfoUpdateState> {
  @override
  DriverVehicleInfoUpdateState build() => const DriverVehicleInfoUpdateState();

  void prefillFromSession({int? vehicleId}) {
    final userData = ref.read(driverAuthProvider).userData;
    final review = DriverSubmissionReviewInfoResolver.fromUserData(userData);
    final vehicle = extractVehicleMap(userData);
    final info = review.vehicle;

    state = state.copyWith(
      vehicleId: vehicleId ?? review.vehicleId,
      sidUserId: readVehicleSidUserId(userData),
      brand: pickVehicleText([info?.brand, vehicle?['brand']]) ?? state.brand,
      model: pickVehicleText([info?.model, vehicle?['model']]) ?? state.model,
      year: pickVehicleText([info?.year, vehicle?['year']]) ?? state.year,
      color: pickVehicleText([info?.color, vehicle?['color']]) ?? state.color,
      licensePlate:
          pickVehicleText([
            info?.licensePlate,
            vehicle?['licensePlate'],
            vehicle?['matricule'],
          ]) ??
          state.licensePlate,
      selectedRange:
          pickVehicleText([
            info?.range,
            vehicle?['range'],
            vehicle?['requestedRange'],
          ])?.toUpperCase() ??
          state.selectedRange,
      airConditioning: readVehicleBool(vehicle?['airConditioning']) ?? false,
      errorMessage: null,
      success: false,
    );
  }

  void setBrand(String value) => _updateText(brand: value);

  void setModel(String value) => _updateText(model: value);

  void setYear(String value) => _updateText(year: value);

  void setColor(String value) => _updateText(color: value);

  void setLicensePlate(String value) => _updateText(licensePlate: value);

  void setRange(String value) {
    final range = value.trim().toUpperCase();
    state = state.copyWith(
      selectedRange: range.isEmpty ? state.selectedRange : range,
      errorMessage: null,
      success: false,
    );
  }

  void setAirConditioning(bool value) {
    state = state.copyWith(
      airConditioning: value,
      errorMessage: null,
      success: false,
    );
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (!state.canSubmit) {
      state = state.copyWith(
        errorMessage:
            'Merci de renseigner toutes les informations du vehicule.',
        success: false,
      );
      return;
    }

    final vehicleId = state.vehicleId;
    if (vehicleId == null) {
      state = state.copyWith(
        errorMessage: 'Impossible d\'identifier le vehicule a mettre a jour.',
        success: false,
      );
      return;
    }

    final update = DriverVehicleUpdate(
      brand: state.brand,
      model: state.model,
      year: state.year,
      color: state.color,
      licensePlate: state.licensePlate,
      range: state.selectedRange,
      airConditioning: state.airConditioning,
      sidUserId: state.sidUserId,
    );

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      success: false,
    );

    final result = await ref.read(updateDriverVehicleUseCaseProvider)(
      UpdateDriverVehicleParams(vehicleId: vehicleId, update: update),
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
      },
      (response) async {
        await _syncVehicleSession(response, update);
        state = state.copyWith(isSubmitting: false, success: true);
      },
    );
  }

  void clearFeedback() {
    state = state.copyWith(errorMessage: null, success: false);
  }

  void _updateText({
    String? brand,
    String? model,
    String? year,
    String? color,
    String? licensePlate,
  }) {
    state = state.copyWith(
      brand: brand ?? state.brand,
      model: model ?? state.model,
      year: year ?? state.year,
      color: color ?? state.color,
      licensePlate: licensePlate ?? state.licensePlate,
      errorMessage: null,
      success: false,
    );
  }

  Future<void> _syncVehicleSession(
    Map<String, dynamic> response,
    DriverVehicleUpdate update,
  ) async {
    final patch = buildVehicleSessionPatch(
      currentUserData: ref.read(driverAuthProvider).userData,
      response: response,
      update: update,
      fallbackVehicleId: state.vehicleId,
    );
    await ref
        .read(driverAuthProvider.notifier)
        .updateUserData(patch.toUserDataPatch());
    await ref.read(driverAuthProvider.notifier).refreshProfile();
  }
}

const Object _sentinel = Object();
