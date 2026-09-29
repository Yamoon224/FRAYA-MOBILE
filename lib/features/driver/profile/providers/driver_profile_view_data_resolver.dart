library;

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/map_parsing_utils.dart';
import '../../../../core/utils/vehicle_ui_utils.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../models/driver_profile_view_data.dart';
import 'driver_profile_document_specs.dart';

class DriverProfileViewDataResolver {
  static String? resolveBackendFieldUrl(
    Map<String, dynamic> userData,
    String backendField,
  ) {
    final vehicle = _extractVehicle(userData);
    final kyc = _extractKyc(userData, vehicle);
    final candidates = <Map<String, dynamic>>[userData];
    if (vehicle != null) candidates.add(vehicle);
    if (kyc != null) candidates.add(kyc);
    return _resolveUrl(_findText(candidates, [backendField]));
  }

  static DriverProfileViewData fromUserData(Map<String, dynamic> userData) {
    final vehicle = _extractVehicle(userData);
    final kyc = _extractKyc(userData, vehicle);
    final candidates = <Map<String, dynamic>>[userData];
    if (vehicle != null) candidates.add(vehicle);
    if (kyc != null) candidates.add(kyc);

    final documents = driverProfileDocumentSpecs
        .map((spec) => _buildDocument(spec, candidates))
        .toList(growable: false);
    final hasDocumentEndpoint = documents.any((doc) => doc.documentUrl != null);

    return DriverProfileViewData(
      vehicle: _buildVehicleViewData(userData, vehicle),
      documents: documents,
      hasDocumentEndpoint: hasDocumentEndpoint,
    );
  }

  static DriverProfileVehicleViewData? _buildVehicleViewData(
    Map<String, dynamic> userData,
    Map<String, dynamic>? vehicle,
  ) {
    final brand = _readText([vehicle?['brand'], userData['brand']]);
    final model = _readText([vehicle?['model'], userData['model']]);
    final year = _readText([vehicle?['year'], userData['year']]);
    final color = _readText([vehicle?['color'], userData['color']]);
    final licensePlate = _readText([
      vehicle?['licensePlate'],
      vehicle?['matricule'],
      userData['licensePlate'],
      userData['matricule'],
    ]);
    final range = _readText([
      vehicle?['requestedRange'],
      vehicle?['range'],
      userData['requestedRange'],
      userData['range'],
    ]);

    final hasAnyVehicleData = [
      brand,
      model,
      year,
      color,
      licensePlate,
      range,
    ].any((value) => value != null);
    if (!hasAnyVehicleData) return null;

    final name = [brand, model].whereType<String>().join(' ').trim();
    final subtitle = [year, color].whereType<String>().join(' - ').trim();

    return DriverProfileVehicleViewData(
      name: name.isEmpty ? 'Véhicule' : name,
      subtitle: subtitle.isEmpty ? 'Infos non renseignées' : subtitle,
      plate: licensePlate ?? 'Plaque non renseignée',
      rangeLabel: range == null ? 'Standard' : VehicleUiUtils.rangeLabel(range),
    );
  }

  static DriverProfileDocumentViewData _buildDocument(
    DriverProfileDocumentSpec spec,
    List<Map<String, dynamic>> candidates,
  ) {
    final url = _resolveUrl(_findText(candidates, spec.urlKeys));
    final expiryText = _findText(candidates, spec.expiryKeys);
    final expiryDate = DateTime.tryParse(expiryText ?? '');
    final statusText = _normalizeStatus(
      _findText(candidates, spec.statusKeys) ??
          _findText(candidates, const ['kycStatus', 'status']),
    );

    final status = _resolveStatus(statusText, expiryDate, url);
    return DriverProfileDocumentViewData(
      type: spec.type,
      section: spec.type.section,
      label: spec.label,
      expiryLabel: _formatExpiry(expiryText, expiryDate),
      statusLabel: _statusLabel(status),
      status: status,
      documentUrl: url,
    );
  }

  static DriverProfileDocumentStatus _resolveStatus(
    String? normalizedStatus,
    DateTime? expiryDate,
    String? documentUrl,
  ) {
    if (normalizedStatus == 'REJECTED') {
      return DriverProfileDocumentStatus.rejected;
    }
    if (normalizedStatus == 'PENDING_VALIDATION') {
      return DriverProfileDocumentStatus.pending;
    }
    if (expiryDate != null) {
      final now = DateTime.now();
      final daysLeft = expiryDate.difference(now).inDays;
      if (daysLeft <= 45) {
        return DriverProfileDocumentStatus.expiringSoon;
      }
    }
    if (normalizedStatus == 'APPROVED' || documentUrl != null) {
      return DriverProfileDocumentStatus.valid;
    }
    return DriverProfileDocumentStatus.missing;
  }

  static String _statusLabel(DriverProfileDocumentStatus status) {
    return switch (status) {
      DriverProfileDocumentStatus.valid => 'Valide',
      DriverProfileDocumentStatus.expiringSoon => 'Expire bientôt',
      DriverProfileDocumentStatus.pending => 'En attente',
      DriverProfileDocumentStatus.rejected => 'Rejeté',
      DriverProfileDocumentStatus.missing => 'Non fourni',
    };
  }

  static String _formatExpiry(String? raw, DateTime? parsed) {
    if (raw == null || raw.trim().isEmpty) return 'N/A';
    if (parsed == null) return raw;
    final month = parsed.month.toString().padLeft(2, '0');
    return '$month/${parsed.year}';
  }

  static String? _findText(List<Map<String, dynamic>> maps, List<String> keys) {
    for (final map in maps) {
      for (final key in keys) {
        final value = map[key];
        final direct = _asText(value);
        if (direct != null) return direct;
        if (value is Map) {
          final nested = _readText([
            value['url'],
            value['path'],
            value['file'],
            value['fileUrl'],
            value['expiresAt'],
            value['expirationDate'],
          ]);
          if (nested != null) return nested;
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? _extractVehicle(Map<String, dynamic> userData) {
    final direct = nestedMap(userData, const ['vehicle', 'vehicule']);
    if (direct != null) return direct;
    final vehicles = userData['vehicles'];
    if (vehicles is! List) return null;
    for (final item in vehicles) {
      if (item is Map) return Map<String, dynamic>.from(item);
    }
    return null;
  }

  static Map<String, dynamic>? _extractKyc(
    Map<String, dynamic> userData,
    Map<String, dynamic>? vehicle,
  ) {
    final direct = nestedMap(userData, const ['kyc', 'lastKyc']);
    if (direct != null) return direct;

    final fromUser = _extractFirstMapFromList(userData['kycs']);
    if (fromUser != null) return fromUser;

    return _extractFirstMapFromList(vehicle?['kycs']);
  }

  static Map<String, dynamic>? _extractFirstMapFromList(dynamic value) {
    if (value is! List) return null;
    for (final item in value) {
      if (item is Map) return Map<String, dynamic>.from(item);
    }
    return null;
  }

  static String? _readText(List<dynamic> values) {
    for (final value in values) {
      final text = _asText(value);
      if (text != null) return text;
    }
    return null;
  }

  static String? _asText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static String _normalizeStatus(String? rawStatus) {
    final status = rawStatus?.trim().toUpperCase().replaceAll('-', '_');
    if (status == null || status.isEmpty) return 'NOT_SUBMITTED';
    if (const {'APPROVED', 'VALIDATED', 'ACTIVE'}.contains(status)) {
      return 'APPROVED';
    }
    if (const {
      'PENDING_VALIDATION',
      'PENDING',
      'UNDER_REVIEW',
      'SUBMITTED',
    }.contains(status)) {
      return 'PENDING_VALIDATION';
    }
    if (const {'REJECTED', 'REFUSED'}.contains(status)) return 'REJECTED';
    return status;
  }

  static String? _resolveUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/drives/')) {
      final origin = Uri.parse(AppConfig.instance.baseUrl);
      return '${origin.scheme}://${origin.authority}$value';
    }
    final safePath = value.startsWith('/') ? value : '/$value';
    return '${Env.drivesBaseUrl}$safePath';
  }
}
