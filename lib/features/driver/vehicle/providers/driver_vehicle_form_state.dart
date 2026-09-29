library;

import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_vehicle_document_type.dart';

class DriverVehicleFormState {
  const DriverVehicleFormState({
    this.brand = '',
    this.model = '',
    this.year = '',
    this.color = '',
    this.licensePlate = '',
    this.selectedRange = 'MAGIC',
    this.airConditioning = false,
    this.documents = const {},
    this.processingDocuments = const {},
    this.isSubmitting = false,
    this.errorMessage,
    this.lastSubmittedAt,
  });

  final String brand;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final String selectedRange;
  final bool airConditioning;
  final Map<DriverVehicleDocumentType, DriverKycDocumentFile> documents;
  final Set<DriverVehicleDocumentType> processingDocuments;
  final bool isSubmitting;
  final String? errorMessage;
  final DateTime? lastSubmittedAt;

  bool get canSubmit =>
      brand.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      year.trim().isNotEmpty &&
      color.trim().isNotEmpty &&
      licensePlate.trim().isNotEmpty &&
      selectedRange.trim().isNotEmpty &&
      DriverVehicleDocumentType.values.every(documents.containsKey) &&
      processingDocuments.isEmpty &&
      !isSubmitting;

  DriverVehicleFormState copyWith({
    String? brand,
    String? model,
    String? year,
    String? color,
    String? licensePlate,
    String? selectedRange,
    bool? airConditioning,
    Map<DriverVehicleDocumentType, DriverKycDocumentFile>? documents,
    Set<DriverVehicleDocumentType>? processingDocuments,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? lastSubmittedAt = _sentinel,
  }) {
    return DriverVehicleFormState(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      selectedRange: selectedRange ?? this.selectedRange,
      airConditioning: airConditioning ?? this.airConditioning,
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
