library;

import 'driver_kyc_document_file.dart';
import 'driver_kyc_document_type.dart';

class DriverKycSubmission {
  const DriverKycSubmission({required this.documents});

  final Map<DriverKycDocumentType, DriverKycDocumentFile> documents;
}
