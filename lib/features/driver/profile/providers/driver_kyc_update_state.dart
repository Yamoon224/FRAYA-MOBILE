library;

import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';

enum DriverKycUpdateMode { onboardingCorrection, profileDocumentUpdate }

enum DriverKycUpdateDocumentGroup { personal, vehicle }

class DriverKycUpdateCompletion {
  const DriverKycUpdateCompletion({
    required this.submittedDocuments,
    required this.status,
    required this.message,
  });

  final Set<DriverKycDocumentType> submittedDocuments;
  final String status;
  final String message;

  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isPending => status == 'PENDING_VALIDATION';
}

class DriverKycUpdateState {
  const DriverKycUpdateState({
    this.selectedDocuments = const {},
    this.processingDocuments = const {},
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
    this.completion,
  });

  final Map<DriverKycDocumentType, DriverKycDocumentFile> selectedDocuments;
  final Set<DriverKycDocumentType> processingDocuments;
  final bool isSubmitting;
  final String? errorMessage;
  final bool success;
  final DriverKycUpdateCompletion? completion;

  bool get canSubmit =>
      driverKycUpdateDocuments.any(selectedDocuments.containsKey) &&
      processingDocuments.isEmpty &&
      !isSubmitting;

  bool canSubmitFor(DriverKycUpdateDocumentGroup group) {
    final documents = group == DriverKycUpdateDocumentGroup.vehicle
        ? driverKycVehicleDocuments
        : driverKycUpdateDocuments;
    return documents.any(selectedDocuments.containsKey) &&
        processingDocuments.isEmpty &&
        !isSubmitting;
  }

  DriverKycUpdateState copyWith({
    Map<DriverKycDocumentType, DriverKycDocumentFile>? selectedDocuments,
    Set<DriverKycDocumentType>? processingDocuments,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    bool? success,
    Object? completion = _sentinel,
  }) {
    return DriverKycUpdateState(
      selectedDocuments: selectedDocuments ?? this.selectedDocuments,
      processingDocuments: processingDocuments ?? this.processingDocuments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      success: success ?? this.success,
      completion: completion == _sentinel
          ? this.completion
          : completion as DriverKycUpdateCompletion?,
    );
  }
}

const _sentinel = Object();
