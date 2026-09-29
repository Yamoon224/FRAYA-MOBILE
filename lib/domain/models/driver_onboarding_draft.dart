library;

import 'driver_kyc_document_file.dart';
import 'driver_kyc_document_type.dart';
import 'driver_vehicle_document_type.dart';

class DriverOnboardingDraft {
  const DriverOnboardingDraft({
    this.kycDocuments = const {},
    this.vehicleDocuments = const {},
    this.brand,
    this.model,
    this.year,
    this.color,
    this.licensePlate,
    this.range,
    this.airConditioning,
    required this.updatedAt,
  });

  final Map<DriverKycDocumentType, DriverKycDocumentFile> kycDocuments;
  final Map<DriverVehicleDocumentType, DriverKycDocumentFile> vehicleDocuments;
  final String? brand;
  final String? model;
  final String? year;
  final String? color;
  final String? licensePlate;
  final String? range;
  final bool? airConditioning;
  final DateTime updatedAt;

  factory DriverOnboardingDraft.empty() {
    return DriverOnboardingDraft(updatedAt: DateTime.now());
  }

  factory DriverOnboardingDraft.fromMap(Map<String, dynamic> map) {
    return DriverOnboardingDraft(
      kycDocuments: _decodeKycDocuments(map['kycDocuments']),
      vehicleDocuments: _decodeVehicleDocuments(map['vehicleDocuments']),
      brand: _readOptionalString(map['brand']),
      model: _readOptionalString(map['model']),
      year: _readOptionalString(map['year']),
      color: _readOptionalString(map['color']),
      licensePlate: _readOptionalString(map['licensePlate']),
      range: _readOptionalString(map['range']),
      airConditioning: map['airConditioning'] == true,
      updatedAt: DateTime.tryParse('${map['updatedAt']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kycDocuments': _encodeDocuments(kycDocuments),
      'vehicleDocuments': _encodeDocuments(vehicleDocuments),
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'licensePlate': licensePlate,
      'range': range,
      'airConditioning': airConditioning,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DriverOnboardingDraft copyWith({
    Map<DriverKycDocumentType, DriverKycDocumentFile>? kycDocuments,
    Map<DriverVehicleDocumentType, DriverKycDocumentFile>? vehicleDocuments,
    Object? brand = _sentinel,
    Object? model = _sentinel,
    Object? year = _sentinel,
    Object? color = _sentinel,
    Object? licensePlate = _sentinel,
    Object? range = _sentinel,
    bool? airConditioning,
    DateTime? updatedAt,
  }) {
    return DriverOnboardingDraft(
      kycDocuments: kycDocuments ?? this.kycDocuments,
      vehicleDocuments: vehicleDocuments ?? this.vehicleDocuments,
      brand: identical(brand, _sentinel) ? this.brand : brand as String?,
      model: identical(model, _sentinel) ? this.model : model as String?,
      year: identical(year, _sentinel) ? this.year : year as String?,
      color: identical(color, _sentinel) ? this.color : color as String?,
      licensePlate: identical(licensePlate, _sentinel)
          ? this.licensePlate
          : licensePlate as String?,
      range: identical(range, _sentinel) ? this.range : range as String?,
      airConditioning: airConditioning ?? this.airConditioning,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

Map<String, Map<String, dynamic>> _encodeDocuments<T extends Enum>(
  Map<T, DriverKycDocumentFile> documents,
) {
  return {
    for (final entry in documents.entries) entry.key.name: _encodeFile(entry.value),
  };
}

Map<DriverKycDocumentType, DriverKycDocumentFile> _decodeKycDocuments(
  Object? raw,
) {
  return _decodeDocuments(raw, DriverKycDocumentType.values.asNameMap());
}

Map<DriverVehicleDocumentType, DriverKycDocumentFile> _decodeVehicleDocuments(
  Object? raw,
) {
  return _decodeDocuments(raw, DriverVehicleDocumentType.values.asNameMap());
}

Map<T, DriverKycDocumentFile> _decodeDocuments<T extends Enum>(
  Object? raw,
  Map<String, T> enumMap,
) {
  if (raw is! Map) {
    return const {};
  }

  final documents = <T, DriverKycDocumentFile>{};
  for (final entry in raw.entries) {
    final key = enumMap['${entry.key}'];
    final value = _decodeFile(entry.value);
    if (key != null && value != null) {
      documents[key] = value;
    }
  }
  return documents;
}

Map<String, dynamic> _encodeFile(DriverKycDocumentFile file) {
  return {
    'path': file.path,
    'fileName': file.fileName,
    'mimeType': file.mimeType,
    'source': file.source.name,
  };
}

DriverKycDocumentFile? _decodeFile(Object? raw) {
  if (raw is! Map) {
    return null;
  }

  final path = _readOptionalString(raw['path']);
  final fileName = _readOptionalString(raw['fileName']);
  final mimeType = _readOptionalString(raw['mimeType']);
  final source = _decodeSource(raw['source']);
  if (path == null || fileName == null || mimeType == null || source == null) {
    return null;
  }

  return DriverKycDocumentFile(
    path: path,
    fileName: fileName,
    mimeType: mimeType,
    source: source,
  );
}

DriverKycDocumentSource? _decodeSource(Object? raw) {
  final name = _readOptionalString(raw);
  if (name == null) {
    return null;
  }
  for (final source in DriverKycDocumentSource.values) {
    if (source.name == name) {
      return source;
    }
  }
  return null;
}

String? _readOptionalString(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return raw;
  }
  return null;
}

const Object _sentinel = Object();
