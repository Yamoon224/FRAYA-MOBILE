library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/driver_document_preparation_service.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../../../../domain/models/driver_onboarding_draft.dart';
import '../../../../domain/models/driver_kyc_submission.dart';
import '../../../../domain/repositories/driver_onboarding_draft_repository.dart';
import '../../../../domain/usecases/driver/kyc/submit_driver_kyc_usecase.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../onboarding/providers/driver_onboarding_draft_dependencies.dart';
import 'driver_kyc_dependencies.dart';
import 'driver_kyc_form_state.dart';

class DriverKycNotifier extends StateNotifier<DriverKycFormState> {
  DriverKycNotifier({
    required Ref ref,
    required SubmitDriverKycUseCase submitUseCase,
    required DriverOnboardingDraftRepository draftRepository,
    DriverDocumentPreparationService? preparationService,
  }) : _ref = ref,
       _submitUseCase = submitUseCase,
       _draftRepository = draftRepository,
       _preparationService =
           preparationService ?? DriverDocumentPreparationService(),
       super(const DriverKycFormState()) {
    unawaited(_restoreDraft());
  }

  final Ref _ref;
  final SubmitDriverKycUseCase _submitUseCase;
  final DriverOnboardingDraftRepository _draftRepository;
  final DriverDocumentPreparationService _preparationService;

  Future<void> setDocument(
    DriverKycDocumentType type,
    DriverKycDocumentFile document,
  ) async {
    _setProcessing(type, true);
    DriverKycDocumentFile? prepared;
    try {
      prepared = await _preparationService.prepare(document);
      final persisted = await _draftRepository.persistDocument(
        prepared,
        namespace: 'kyc_${type.name}',
      );
      final previous = state.documents[type];
      if (previous != null && previous.path != persisted.path) {
        await _draftRepository.removePersistedDocument(previous.path);
      }

      final documents = Map<DriverKycDocumentType, DriverKycDocumentFile>.from(
        state.documents,
      )..[type] = persisted;
      state = state.copyWith(documents: documents, errorMessage: null);
      await _saveDraft(documents);
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

  Future<void> removeDocument(DriverKycDocumentType type) async {
    final previous = state.documents[type];
    final documents = Map<DriverKycDocumentType, DriverKycDocumentFile>.from(
      state.documents,
    )..remove(type);
    state = state.copyWith(documents: documents, errorMessage: null);

    if (previous != null) {
      await _draftRepository.removePersistedDocument(previous.path);
    }
    await _saveDraft(documents);
  }

  Future<void> submit() async {
    if (state.isSubmitting || !state.canSubmit) {
      return;
    }

    final authState = _ref.read(driverAuthProvider);
    final driverId = authState.userData?['driverId'];
    if (driverId is! int) {
      state = state.copyWith(
        errorMessage: 'Impossible d\'identifier le chauffeur connecté.',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final result = await _submitUseCase(
      SubmitDriverKycParams(
        userId: driverId,
        submission: DriverKycSubmission(
          documents: _driverDocumentsOnly(state.documents),
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
      (_) async {
        final authNotifier = _ref.read(driverAuthProvider.notifier);
        await authNotifier.updateUserData({'kycStatus': 'PENDING_VALIDATION'});
        await authNotifier.refreshProfile();
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: null,
          lastSubmittedAt: DateTime.now(),
        );
      },
    );
  }

  Future<void> _restoreDraft() async {
    final draft = await _draftRepository.readDraft();
    if (draft == null || draft.kycDocuments.isEmpty) {
      return;
    }

    state = state.copyWith(documents: draft.kycDocuments, errorMessage: null);
  }

  Future<void> _saveDraft(
    Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  ) async {
    final existingDraft = await _draftRepository.readDraft();
    final draft = (existingDraft ?? DriverOnboardingDraft.empty()).copyWith(
      kycDocuments: documents,
      updatedAt: DateTime.now(),
    );
    await _draftRepository.saveDraft(draft);
  }

  void _setProcessing(DriverKycDocumentType type, bool isProcessing) {
    final processing = Set<DriverKycDocumentType>.from(
      state.processingDocuments,
    );
    isProcessing ? processing.add(type) : processing.remove(type);
    state = state.copyWith(processingDocuments: processing);
  }
}

Map<DriverKycDocumentType, DriverKycDocumentFile> _driverDocumentsOnly(
  Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
) {
  return {
    for (final type in driverKycDriverDocuments)
      if (documents[type] != null) type: documents[type]!,
  };
}

final driverKycFormProvider =
    StateNotifierProvider<DriverKycNotifier, DriverKycFormState>((ref) {
      return DriverKycNotifier(
        ref: ref,
        submitUseCase: ref.watch(submitDriverKycUseCaseProvider),
        draftRepository: ref.watch(driverOnboardingDraftRepositoryProvider),
        preparationService: ref.watch(driverDocumentPreparationServiceProvider),
      );
    });
