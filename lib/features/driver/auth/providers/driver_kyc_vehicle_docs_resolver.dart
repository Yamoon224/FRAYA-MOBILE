library;

import '../../../../domain/models/driver_kyc_document_type.dart';

class DriverKycVehicleDocsState {
  const DriverKycVehicleDocsState({
    required this.hasKycRecord,
    required this.missingDocuments,
  });

  final bool hasKycRecord;
  final Set<DriverKycDocumentType> missingDocuments;

  bool get hasAllVehicleDocuments => hasKycRecord && missingDocuments.isEmpty;
  bool get needsVehicleCompletion =>
      hasKycRecord && missingDocuments.isNotEmpty;
}

abstract final class DriverKycVehicleDocsResolver {
  static DriverKycVehicleDocsState resolve(Map<String, dynamic>? userData) {
    final kyc = _extractKyc(userData);
    if (kyc == null) {
      return const DriverKycVehicleDocsState(
        hasKycRecord: false,
        missingDocuments: {},
      );
    }

    final missing = <DriverKycDocumentType>{};
    for (final type in driverKycVehicleDocuments) {
      if (!_hasValue(kyc[type.backendField])) {
        missing.add(type);
      }
    }

    return DriverKycVehicleDocsState(
      hasKycRecord: true,
      missingDocuments: missing,
    );
  }

  static bool hasVehicleKycDocuments(Map<String, dynamic>? userData) {
    return resolve(userData).hasAllVehicleDocuments;
  }

  static Set<DriverKycDocumentType> missingVehicleKycDocuments(
    Map<String, dynamic>? userData,
  ) {
    return resolve(userData).missingDocuments;
  }

  static Map<String, dynamic>? _extractKyc(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    for (final key in const ['kyc', 'lastKyc']) {
      final value = userData[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    final kycs = userData['kycs'];
    if (kycs is! List) return null;

    final items = kycs
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (items.isEmpty) return null;

    items.sort((a, b) => _timestamp(b).compareTo(_timestamp(a)));
    return items.first;
  }

  static DateTime _timestamp(Map<String, dynamic> kyc) {
    for (final key in const [
      'updatedAt',
      'updateAt',
      'createdAt',
      'createAt',
    ]) {
      final value = kyc[key]?.toString();
      if (value == null || value.trim().isEmpty) continue;
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static bool _hasValue(dynamic value) {
    final text = value?.toString().trim();
    return text != null && text.isNotEmpty && text != 'null';
  }
}
