library;

import '../models/driver_kyc_document_file.dart';
import '../models/driver_kyc_document_type.dart';
import '../models/driver_kyc_submission.dart';

abstract class DriverKycRepository {
  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required DriverKycSubmission submission,
  });

  Future<Map<String, dynamic>> updateKyc({
    required int kycId,
    required Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  });

  Future<Map<String, dynamic>> getKycBySidUser({required int sidUserId});
}
