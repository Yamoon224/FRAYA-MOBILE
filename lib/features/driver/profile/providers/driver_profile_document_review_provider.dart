library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/driver_kyc_document_type.dart';
import '../models/driver_profile_view_data.dart';

final driverProfileDocumentReviewProvider =
    NotifierProvider<
      DriverProfileDocumentReviewNotifier,
      Map<DriverKycDocumentType, DriverProfileDocumentStatus>
    >(DriverProfileDocumentReviewNotifier.new);

class DriverProfileDocumentReviewNotifier
    extends Notifier<Map<DriverKycDocumentType, DriverProfileDocumentStatus>> {
  @override
  Map<DriverKycDocumentType, DriverProfileDocumentStatus> build() {
    return const <DriverKycDocumentType, DriverProfileDocumentStatus>{};
  }

  void markDocuments(
    Iterable<DriverKycDocumentType> documents,
    DriverProfileDocumentStatus status,
  ) {
    final next = Map<DriverKycDocumentType, DriverProfileDocumentStatus>.from(
      state,
    );
    for (final document in documents) {
      if (driverKycUpdateDocuments.contains(document) ||
          driverKycVehicleDocuments.contains(document)) {
        next[document] = status;
      }
    }
    state = next;
  }

  void clear() {
    state = const <DriverKycDocumentType, DriverProfileDocumentStatus>{};
  }
}

List<DriverProfileDocumentViewData> applyDriverProfileDocumentReviewOverrides({
  required List<DriverProfileDocumentViewData> documents,
  required Map<DriverKycDocumentType, DriverProfileDocumentStatus> overrides,
}) {
  if (overrides.isEmpty) {
    return documents;
  }

  return documents
      .map((document) {
        final status = overrides[document.type];
        return status == null
            ? document
            : DriverProfileDocumentViewData(
                type: document.type,
                section: document.section,
                label: document.label,
                expiryLabel: document.expiryLabel,
                statusLabel: _statusLabel(status),
                status: status,
                documentUrl: document.documentUrl,
              );
      })
      .toList(growable: false);
}

String _statusLabel(DriverProfileDocumentStatus status) {
  return switch (status) {
    DriverProfileDocumentStatus.valid => 'Valide',
    DriverProfileDocumentStatus.expiringSoon => 'Expire bientôt',
    DriverProfileDocumentStatus.pending => 'En attente',
    DriverProfileDocumentStatus.rejected => 'Rejeté',
    DriverProfileDocumentStatus.missing => 'Non fourni',
  };
}
