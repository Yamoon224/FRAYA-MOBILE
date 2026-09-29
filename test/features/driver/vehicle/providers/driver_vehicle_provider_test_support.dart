import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_onboarding_draft.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_submission.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_update.dart';
import 'package:fraya_mobile/domain/repositories/driver_onboarding_draft_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_vehicle_repository.dart';
import 'package:fraya_mobile/features/driver/vehicle/providers/driver_vehicle_provider.dart';

class RecordingDriverVehicleRepository implements DriverVehicleRepository {
  DriverVehicleSubmission? lastSubmission;
  DriverVehicleUpdate? lastUpdate;
  int? lastUpdateVehicleId;
  Map<String, dynamic> response = const {'id': 17, 'vehicleStatus': 'PENDING'};
  Object? error;

  @override
  Future<Map<String, dynamic>> submitVehicle({
    required DriverVehicleSubmission submission,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastSubmission = submission;
    return response;
  }

  @override
  Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required DriverVehicleUpdate update,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastUpdateVehicleId = vehicleId;
    lastUpdate = update;
    return response;
  }
}

class InMemoryDriverOnboardingDraftRepository
    implements DriverOnboardingDraftRepository {
  DriverOnboardingDraft? draft;
  final Set<String> existingPaths = <String>{};
  bool clearCalled = false;

  @override
  Future<DriverOnboardingDraft?> readDraft() async => draft;

  @override
  Future<void> saveDraft(DriverOnboardingDraft draft) async {
    this.draft = draft;
  }

  @override
  Future<void> clearDraft() async {
    clearCalled = true;
    draft = null;
    existingPaths.clear();
  }

  @override
  Future<DriverKycDocumentFile> persistDocument(
    DriverKycDocumentFile file, {
    required String namespace,
  }) async {
    final extension = file.fileName.endsWith('.png') ? '.png' : '.pdf';
    final persistedPath = '/persisted/$namespace$extension';
    existingPaths
      ..remove(file.path)
      ..add(persistedPath);
    return DriverKycDocumentFile(
      path: persistedPath,
      fileName: file.fileName,
      mimeType: file.mimeType,
      source: file.source,
    );
  }

  @override
  Future<void> removePersistedDocument(String path) async {
    existingPaths.remove(path);
  }

  @override
  Future<bool> documentExists(String path) async =>
      existingPaths.contains(path);
}

const List<DriverKycDocumentType> requiredKycTypes = [
  DriverKycDocumentType.photoFrontPermis,
  DriverKycDocumentType.photoBackPermis,
  DriverKycDocumentType.photoSelfPermis,
];

Future<void> fillCompleteVehicleForm(DriverVehicleNotifier notifier) async {
  notifier
    ..setBrand('Toyota')
    ..setModel('Corolla')
    ..setYear('2022')
    ..setColor('Rouge')
    ..setLicensePlate('12ERSTDFD')
    ..setRange('magic');
  for (final type in DriverVehicleDocumentType.values) {
    await notifier.setDocument(
      type,
      pdfDocument('/tmp/${type.backendField}.pdf', '${type.backendField}.pdf'),
    );
  }
}

DriverOnboardingDraft buildKycDraft() {
  return DriverOnboardingDraft(
    kycDocuments: {
      for (final type in requiredKycTypes)
        type: imageDocument('/persisted/${type.name}.png', '${type.name}.png'),
    },
    updatedAt: DateTime(2025),
  );
}

DriverKycDocumentFile pdfDocument(String path, String fileName) {
  return DriverKycDocumentFile.fromPath(
    path: path,
    fileName: fileName,
    source: DriverKycDocumentSource.pdfFile,
  )!;
}

DriverKycDocumentFile imageDocument(String path, String fileName) {
  return DriverKycDocumentFile.fromPath(
    path: path,
    fileName: fileName,
    source: DriverKycDocumentSource.galleryImage,
  )!;
}
