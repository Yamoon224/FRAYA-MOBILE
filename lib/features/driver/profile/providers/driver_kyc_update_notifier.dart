library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/driver_document_preparation_service.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../../../../domain/usecases/driver/kyc/update_driver_kyc_usecase.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../auth/providers/driver_auth_session_status_normalizer.dart';
import '../../kyc/providers/driver_kyc_dependencies.dart';
import 'driver_kyc_update_dependencies.dart';
import 'driver_kyc_update_state.dart';

final driverKycUpdateProvider =
    NotifierProvider<DriverKycUpdateNotifier, DriverKycUpdateState>(
      DriverKycUpdateNotifier.new,
      isAutoDispose: true,
    );

class DriverKycUpdateNotifier extends Notifier<DriverKycUpdateState> {
  late final DriverDocumentPreparationService _preparationService;
  final Map<DriverKycDocumentType, DriverKycDocumentFile> _temporaryDocuments =
      {};

  @override
  DriverKycUpdateState build() {
    _preparationService = ref.read(driverDocumentPreparationServiceProvider);
    ref.onDispose(() {
      unawaited(_cleanupDocuments(_temporaryDocuments.values.toList()));
    });
    return const DriverKycUpdateState();
  }

  Future<void> setDocument(
    DriverKycDocumentType type,
    DriverKycDocumentFile file,
  ) async {
    _setProcessing(type, true);
    try {
      final prepared = await _preparationService.prepare(file);
      final previous = state.selectedDocuments[type];
      state = state.copyWith(
        selectedDocuments: {...state.selectedDocuments, type: prepared},
        errorMessage: null,
      );
      _temporaryDocuments[type] = prepared;
      if (previous != null && previous.path != prepared.path) {
        await _preparationService.cleanupTemporary(previous);
      }
    } on DocumentPreparationException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Impossible de préparer ce document.',
      );
    } finally {
      _setProcessing(type, false);
    }
  }

  Future<void> removeDocument(DriverKycDocumentType type) async {
    final previous = state.selectedDocuments[type];
    final updated = Map<DriverKycDocumentType, DriverKycDocumentFile>.from(
      state.selectedDocuments,
    )..remove(type);
    state = state.copyWith(selectedDocuments: updated);
    _temporaryDocuments.remove(type);
    if (previous != null) {
      await _preparationService.cleanupTemporary(previous);
    }
  }

  Future<void> submit(
    int kycId, {
    DriverKycUpdateMode mode = DriverKycUpdateMode.onboardingCorrection,
    DriverKycUpdateDocumentGroup documentGroup =
        DriverKycUpdateDocumentGroup.personal,
  }) async {
    if (!state.canSubmitFor(documentGroup)) return;

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      success: false,
      completion: null,
    );

    final useCase = ref.read(updateDriverKycUseCaseProvider);
    final documents = documentGroup == DriverKycUpdateDocumentGroup.vehicle
        ? _vehicleDocumentsOnly(state.selectedDocuments)
        : _updateDocumentsOnly(state.selectedDocuments);
    final result = await useCase(
      UpdateDriverKycParams(kycId: kycId, documents: documents),
    );

    await result.fold(
      (failure) async => state = state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      ),
      (response) async {
        final completion = _buildCompletion(response, documents.keys.toSet());
        await _cleanupDocuments(state.selectedDocuments.values);
        _temporaryDocuments.clear();
        state = state.copyWith(
          selectedDocuments: const {},
          isSubmitting: false,
          success: true,
          completion: completion,
        );

        if (mode == DriverKycUpdateMode.onboardingCorrection) {
          final authNotifier = ref.read(driverAuthProvider.notifier);
          await authNotifier.updateUserData({
            'kycStatus': 'PENDING_VALIDATION',
          });
          await authNotifier.refreshProfile();
        }
      },
    );
  }

  void clearFeedback() {
    state = state.copyWith(
      errorMessage: null,
      success: false,
      completion: null,
    );
  }

  void _setProcessing(DriverKycDocumentType type, bool isProcessing) {
    final processing = Set<DriverKycDocumentType>.from(
      state.processingDocuments,
    );
    isProcessing ? processing.add(type) : processing.remove(type);
    state = state.copyWith(processingDocuments: processing);
  }

  Future<void> _cleanupDocuments(
    Iterable<DriverKycDocumentFile> documents,
  ) async {
    for (final document in documents) {
      await _preparationService.cleanupTemporary(document);
    }
  }
}

Map<DriverKycDocumentType, DriverKycDocumentFile> _vehicleDocumentsOnly(
  Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
) {
  return {
    for (final type in driverKycVehicleDocuments)
      if (documents[type] != null) type: documents[type]!,
  };
}

Map<DriverKycDocumentType, DriverKycDocumentFile> _updateDocumentsOnly(
  Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
) {
  return {
    for (final type in driverKycUpdateDocuments)
      if (documents[type] != null) type: documents[type]!,
  };
}

DriverKycUpdateCompletion _buildCompletion(
  Map<String, dynamic> response,
  Set<DriverKycDocumentType> submittedDocuments,
) {
  final payload = _payloadMap(response);
  final status = DriverAuthSessionStatusNormalizer.normalize(
    _findText([payload, response], const ['status', 'kycStatus']),
  );
  final message =
      _findText([payload, response], const ['message', 'description']) ??
      _defaultCompletionMessage(status);
  return DriverKycUpdateCompletion(
    submittedDocuments: submittedDocuments,
    status: status,
    message: message,
  );
}

Map<String, dynamic> _payloadMap(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  if (data is List) {
    for (final item in data) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
    }
  }
  return const <String, dynamic>{};
}

String? _findText(List<Map<String, dynamic>> candidates, List<String> keys) {
  for (final candidate in candidates) {
    for (final key in keys) {
      final value = candidate[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }
  }
  return null;
}

String _defaultCompletionMessage(String status) {
  return switch (status) {
    'APPROVED' => 'Vos documents ont été validés.',
    'REJECTED' => 'La mise à jour de vos documents a été rejetée.',
    'PENDING_VALIDATION' =>
      'Vos documents ont été envoyés et sont en attente de validation.',
    _ => 'Vos documents ont été envoyés avec succès.',
  };
}
