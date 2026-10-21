library;

import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/failures.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_vehicle_document_type.dart';
import '../../../../domain/usecases/driver/vehicle/request_driver_vehicle_secondary_range_usecase.dart';
import '../../../../domain/usecases/driver/vehicle/update_driver_vehicle_secondary_range_usecase.dart';
import 'driver_vehicle_dependencies.dart';

/// Paramètres de l'écran « Gérer mes gammes » (valeur comparable pour le provider famille).
class DriverVehicleRangesArgs {
  const DriverVehicleRangesArgs({
    required this.vehicleId,
    required this.primaryRange,
    required this.currentSecondaryRange,
  });

  final int vehicleId;
  final String primaryRange;
  final String? currentSecondaryRange;

  @override
  bool operator ==(Object other) =>
      other is DriverVehicleRangesArgs &&
      other.vehicleId == vehicleId &&
      other.primaryRange == primaryRange &&
      other.currentSecondaryRange == currentSecondaryRange;

  @override
  int get hashCode => Object.hash(vehicleId, primaryRange, currentSecondaryRange);
}

/// Issue d'un envoi réussi.
enum DriverVehicleRangesOutcome {
  /// Modification appliquée tout de suite (retrait ou gamme déjà couverte).
  updated,

  /// Demande envoyée : un administrateur doit l'examiner, le véhicule reste en service.
  requested,
}

class DriverVehicleRangesState {
  const DriverVehicleRangesState({
    required this.primaryRange,
    required this.currentSecondaryRange,
    this.selectedSecondaryRange,
    this.photos = const {},
    this.isSubmitting = false,
    this.errorMessage,
    this.outcome,
  });

  final String primaryRange;
  final String? currentSecondaryRange;
  final String? selectedSecondaryRange;
  final Map<DriverVehicleDocumentType, DriverKycDocumentFile> photos;
  final bool isSubmitting;
  final String? errorMessage;
  final DriverVehicleRangesOutcome? outcome;

  /// Une gamme supérieure à la principale exige les photos et une revue par un administrateur.
  bool get requiresReview =>
      selectedSecondaryRange != null &&
      vehicleRangeLevel(selectedSecondaryRange) > vehicleRangeLevel(primaryRange);

  bool get hasChange => selectedSecondaryRange != currentSecondaryRange;

  bool get hasAllPhotos => vehicleRangePhotoTypes.every(photos.containsKey);

  bool get canSubmit =>
      hasChange && !isSubmitting && (!requiresReview || hasAllPhotos);

  DriverVehicleRangesState copyWith({
    Object? selectedSecondaryRange = _sentinel,
    Map<DriverVehicleDocumentType, DriverKycDocumentFile>? photos,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? outcome = _sentinel,
  }) {
    return DriverVehicleRangesState(
      primaryRange: primaryRange,
      currentSecondaryRange: currentSecondaryRange,
      selectedSecondaryRange: identical(selectedSecondaryRange, _sentinel)
          ? this.selectedSecondaryRange
          : selectedSecondaryRange as String?,
      photos: photos ?? this.photos,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      outcome: identical(outcome, _sentinel)
          ? this.outcome
          : outcome as DriverVehicleRangesOutcome?,
    );
  }
}

const Object _sentinel = Object();

class DriverVehicleRangesNotifier
    extends StateNotifier<DriverVehicleRangesState> {
  DriverVehicleRangesNotifier({
    required DriverVehicleRangesArgs args,
    required UpdateDriverVehicleSecondaryRangeUseCase updateUseCase,
    required RequestDriverVehicleSecondaryRangeUseCase requestUseCase,
  }) : _vehicleId = args.vehicleId,
       _updateUseCase = updateUseCase,
       _requestUseCase = requestUseCase,
       super(
         DriverVehicleRangesState(
           primaryRange: args.primaryRange.trim().toUpperCase(),
           currentSecondaryRange: args.currentSecondaryRange
               ?.trim()
               .toUpperCase(),
           selectedSecondaryRange: args.currentSecondaryRange
               ?.trim()
               .toUpperCase(),
         ),
       );

  final int _vehicleId;
  final UpdateDriverVehicleSecondaryRangeUseCase _updateUseCase;
  final RequestDriverVehicleSecondaryRangeUseCase _requestUseCase;

  /// `null` signifie « aucune seconde gamme ».
  void selectSecondaryRange(String? value) {
    final range = value?.trim().toUpperCase();
    if (range != null && range == state.primaryRange) return;
    state = state.copyWith(selectedSecondaryRange: range, errorMessage: null);
  }

  void setPhoto(DriverVehicleDocumentType type, DriverKycDocumentFile file) {
    if (!vehicleRangePhotoTypes.contains(type)) return;
    state = state.copyWith(
      photos: {...state.photos, type: file},
      errorMessage: null,
    );
  }

  void removePhoto(DriverVehicleDocumentType type) {
    final next = {...state.photos}..remove(type);
    state = state.copyWith(photos: next);
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final selected = state.selectedSecondaryRange;
    final isRequest = state.requiresReview;

    final result = isRequest
        ? await _requestUseCase(
            RequestDriverVehicleSecondaryRangeParams(
              vehicleId: _vehicleId,
              secondaryRange: selected!,
              photos: {
                for (final type in vehicleRangePhotoTypes)
                  type: state.photos[type]!,
              },
            ),
          )
        : await _updateUseCase(
            UpdateDriverVehicleSecondaryRangeParams(
              vehicleId: _vehicleId,
              secondaryRange: selected,
            ),
          );

    result.fold(
      (Failure failure) => state = state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isSubmitting: false,
        outcome: isRequest
            ? DriverVehicleRangesOutcome.requested
            : DriverVehicleRangesOutcome.updated,
      ),
    );
  }
}

final driverVehicleRangesProvider = StateNotifierProvider.autoDispose
    .family<
      DriverVehicleRangesNotifier,
      DriverVehicleRangesState,
      DriverVehicleRangesArgs
    >(
      (ref, args) => DriverVehicleRangesNotifier(
        args: args,
        updateUseCase: ref.watch(
          updateDriverVehicleSecondaryRangeUseCaseProvider,
        ),
        requestUseCase: ref.watch(
          requestDriverVehicleSecondaryRangeUseCaseProvider,
        ),
      ),
    );
