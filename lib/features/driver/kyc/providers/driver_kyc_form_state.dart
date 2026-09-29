library;

import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';

class DriverKycFormState {
  const DriverKycFormState({
    this.documents = const {},
    this.processingDocuments = const {},
    this.isSubmitting = false,
    this.errorMessage,
    this.lastSubmittedAt,
  });

  final Map<DriverKycDocumentType, DriverKycDocumentFile> documents;
  final Set<DriverKycDocumentType> processingDocuments;
  final bool isSubmitting;
  final String? errorMessage;
  final DateTime? lastSubmittedAt;

  bool get canSubmit =>
      driverKycRequiredDocuments.every(documents.containsKey) &&
      processingDocuments.isEmpty &&
      !isSubmitting;

  DriverKycFormState copyWith({
    Map<DriverKycDocumentType, DriverKycDocumentFile>? documents,
    Set<DriverKycDocumentType>? processingDocuments,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? lastSubmittedAt = _sentinel,
  }) {
    return DriverKycFormState(
      documents: documents ?? this.documents,
      processingDocuments: processingDocuments ?? this.processingDocuments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      lastSubmittedAt: identical(lastSubmittedAt, _sentinel)
          ? this.lastSubmittedAt
          : lastSubmittedAt as DateTime?,
    );
  }
}

const Object _sentinel = Object();
