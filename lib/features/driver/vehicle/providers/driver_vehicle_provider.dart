library;

import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/driver_document_preparation_service.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../../../../domain/models/driver_onboarding_draft.dart';
import '../../../../domain/models/driver_vehicle_document_type.dart';
import '../../../../domain/models/driver_vehicle_submission.dart';
import '../../../../domain/repositories/driver_onboarding_draft_repository.dart';
import '../../../../domain/usecases/driver/vehicle/submit_driver_vehicle_usecase.dart';
import '../../auth/providers/driver_submission_review_info.dart';
import 'driver_vehicle_draft_support.dart';
import 'driver_vehicle_form_state.dart';

class DriverVehicleNotifier extends StateNotifier<DriverVehicleFormState> {
  DriverVehicleNotifier({
    required SubmitDriverVehicleUseCase submitUseCase,
    required DriverOnboardingDraftRepository draftRepository,
    required int? Function() readDriverId,
    required DriverVehicleReviewData? Function() readVehicleReviewData,
    required Future<String?> Function(Map<String, dynamic> response)
    syncVehicleSession,
    DriverDocumentPreparationService? preparationService,
  }) : _submitUseCase = submitUseCase,
       _draftRepository = draftRepository,
       _readDriverId = readDriverId,
       _readVehicleReviewData = readVehicleReviewData,
       _syncVehicleSession = syncVehicleSession,
       _preparationService =
           preparationService ?? DriverDocumentPreparationService(),
       super(const DriverVehicleFormState()) {
    unawaited(_restoreDraft());
  }

  final SubmitDriverVehicleUseCase _submitUseCase;
  final DriverOnboardingDraftRepository _draftRepository;
  final int? Function() _readDriverId;
  final DriverVehicleReviewData? Function() _readVehicleReviewData;
  final Future<String?> Function(Map<String, dynamic> response)
  _syncVehicleSession;
  final DriverDocumentPreparationService _preparationService;

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
    );
    unawaited(_saveDraft());
  }

  void setAirConditioning(bool value) {
    state = state.copyWith(airConditioning: value, errorMessage: null);
    unawaited(_saveDraft());
  }

  Future<void> setDocument(
    DriverVehicleDocumentType type,
    DriverKycDocumentFile document,
  ) async {
    _setProcessing(type, true);
    DriverKycDocumentFile? prepared;
    try {
      prepared = await _preparationService.prepare(document);
      final persisted = await _draftRepository.persistDocument(
        prepared,
        namespace: 'vehicle_${type.name}',
      );
      final previous = state.documents[type];
      if (previous != null && previous.path != persisted.path) {
        await _draftRepository.removePersistedDocument(previous.path);
      }

      final documents =
          Map<DriverVehicleDocumentType, DriverKycDocumentFile>.from(
            state.documents,
          )..[type] = persisted;
      state = state.copyWith(documents: documents, errorMessage: null);
      await _saveDraft();
    } on DocumentPreparationException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Impossible d\'enregistrer ce document localement.',
      );
    } finally {
      if (prepared != null && prepared.path != document.path) {
        await _preparationService.cleanupTemporary(prepared);
      }
      _setProcessing(type, false);
    }
  }

  Future<void> removeDocument(DriverVehicleDocumentType type) async {
    final previous = state.documents[type];
    final documents =
        Map<DriverVehicleDocumentType, DriverKycDocumentFile>.from(
          state.documents,
        )..remove(type);
    state = state.copyWith(documents: documents, errorMessage: null);

    if (previous != null) {
      await _draftRepository.removePersistedDocument(previous.path);
    }
    await _saveDraft();
  }

  Future<void> submit() async {
    if (state.isSubmitting) {
      return;
    }

    if (!state.canSubmit) {
      state = state.copyWith(
        errorMessage:
            'Merci de renseigner les informations du véhicule et tous les documents obligatoires.',
      );
      return;
    }

    final driverId = _readDriverId();
    if (driverId == null) {
      state = state.copyWith(
        errorMessage: 'Impossible d\'identifier le chauffeur connecté.',
      );
      return;
    }

    final draft = await _draftRepository.readDraft();
    final kycDocuments = extractVehicleKycDocuments(draft);
    if (kycDocuments == null) {
      state = state.copyWith(
        errorMessage:
            'Documents KYC manquants. Revenez à l\'étape KYC pour recharger les photos du permis.',
      );
      return;
    }
    final missingDocument = await _findMissingDocument(kycDocuments);
    if (missingDocument != null) {
      state = state.copyWith(
        errorMessage:
            'Le document ${missingDocument.label.toLowerCase()} est introuvable sur l appareil. Rechargez-le depuis le KYC.',
      );
      return;
    }
    final missingVehicleDocument = await _findMissingVehicleDocument(
      state.documents,
    );
    if (missingVehicleDocument != null) {
      state = state.copyWith(
        errorMessage:
            'Le document ${missingVehicleDocument.label.toLowerCase()} est introuvable. Rechargez-le avant de continuer.',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _submitUseCase(
      SubmitDriverVehicleParams(
        submission: DriverVehicleSubmission(
          brand: state.brand.trim(),
          model: state.model.trim(),
          year: state.year.trim(),
          color: state.color.trim(),
          licensePlate: state.licensePlate.trim(),
          range: state.selectedRange.trim().toUpperCase(),
          sidUserId: driverId,
          kycDocuments: kycDocuments,
          documents: state.documents,
          airConditioning: state.airConditioning,
        ),
      ),
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
      },
      (response) async {
        final syncError = await _syncVehicleSession(response);
        if (syncError != null) {
          state = state.copyWith(isSubmitting: false, errorMessage: syncError);
          return;
        }

        await _draftRepository.clearDraft();
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: null,
          lastSubmittedAt: DateTime.now(),
        );
      },
    );
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
    );
    unawaited(_saveDraft());
  }

  Future<void> _restoreDraft() async {
    final draft = await _draftRepository.readDraft();
    if (draft == null) {
      _applyVehicleReviewData();
      return;
    }

    final sanitizedDraft = await _removeMissingVehicleDocuments(draft);
    state = restoreVehicleFormState(
      state,
      sanitizedDraft,
    ).copyWith(errorMessage: null);
    if (!identical(sanitizedDraft, draft)) {
      await _draftRepository.saveDraft(sanitizedDraft);
    }
    _applyVehicleReviewData(onlyEmptyFields: true);
  }

  void _applyVehicleReviewData({bool onlyEmptyFields = false}) {
    final vehicle = _readVehicleReviewData();
    if (vehicle == null) return;

    final range = vehicle.range?.trim().toUpperCase();
    state = state.copyWith(
      brand: _prefillText(state.brand, vehicle.brand, onlyEmptyFields),
      model: _prefillText(state.model, vehicle.model, onlyEmptyFields),
      year: _prefillText(state.year, vehicle.year, onlyEmptyFields),
      color: _prefillText(state.color, vehicle.color, onlyEmptyFields),
      licensePlate: _prefillText(
        state.licensePlate,
        vehicle.licensePlate,
        onlyEmptyFields,
      ),
      selectedRange: range != null && range.isNotEmpty
          ? _prefillText(state.selectedRange, range, onlyEmptyFields)
          : state.selectedRange,
      errorMessage: null,
    );
  }

  Future<void> _saveDraft() async {
    final existingDraft = await _draftRepository.readDraft();
    final draft = (existingDraft ?? DriverOnboardingDraft.empty()).copyWith(
      brand: state.brand,
      model: state.model,
      year: state.year,
      color: state.color,
      licensePlate: state.licensePlate,
      range: state.selectedRange,
      airConditioning: state.airConditioning,
      vehicleDocuments: state.documents,
      updatedAt: DateTime.now(),
    );
    await _draftRepository.saveDraft(draft);
  }

  Future<DriverKycDocumentType?> _findMissingDocument(
    Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  ) async {
    for (final entry in documents.entries) {
      final exists = await _draftRepository.documentExists(entry.value.path);
      if (!exists) {
        return entry.key;
      }
    }
    return null;
  }

  Future<DriverVehicleDocumentType?> _findMissingVehicleDocument(
    Map<DriverVehicleDocumentType, DriverKycDocumentFile> documents,
  ) async {
    for (final type in DriverVehicleDocumentType.values) {
      final document = documents[type];
      if (document == null) {
        return type;
      }
      final exists = await _draftRepository.documentExists(document.path);
      if (!exists) {
        return type;
      }
    }
    return null;
  }

  Future<DriverOnboardingDraft> _removeMissingVehicleDocuments(
    DriverOnboardingDraft draft,
  ) async {
    if (draft.vehicleDocuments.isEmpty) {
      return draft;
    }

    final existingDocuments =
        <DriverVehicleDocumentType, DriverKycDocumentFile>{};
    for (final entry in draft.vehicleDocuments.entries) {
      if (await _draftRepository.documentExists(entry.value.path)) {
        existingDocuments[entry.key] = entry.value;
      }
    }
    if (existingDocuments.length == draft.vehicleDocuments.length) {
      return draft;
    }
    return draft.copyWith(vehicleDocuments: existingDocuments);
  }

  void _setProcessing(DriverVehicleDocumentType type, bool isProcessing) {
    final processing = Set<DriverVehicleDocumentType>.from(
      state.processingDocuments,
    );
    isProcessing ? processing.add(type) : processing.remove(type);
    state = state.copyWith(processingDocuments: processing);
  }
}

String _prefillText(String current, String? next, bool onlyEmptyFields) {
  if (next == null || next.trim().isEmpty) return current;
  if (onlyEmptyFields && current.trim().isNotEmpty) return current;
  return next.trim();
}
