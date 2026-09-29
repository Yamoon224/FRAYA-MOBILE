import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/services/driver_document_preparation_service.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';

class PassthroughDriverDocumentPreparationService
    extends DriverDocumentPreparationService {
  DriverKycDocumentFile? replacement;
  Object? error;
  int prepareCalls = 0;
  final List<String> cleanedPaths = [];

  @override
  Future<DriverKycDocumentFile> prepare(DriverKycDocumentFile document) async {
    prepareCalls++;
    if (error != null) throw error!;
    if (!DriverKycDocumentFile.isSupported(document.path)) {
      throw const DocumentPreparationException(
        message: 'Formats autorisés : PDF, JPG, JPEG ou PNG.',
      );
    }
    return replacement ?? document;
  }

  @override
  Future<void> cleanupTemporary(DriverKycDocumentFile document) async {
    cleanedPaths.add(document.path);
  }
}
