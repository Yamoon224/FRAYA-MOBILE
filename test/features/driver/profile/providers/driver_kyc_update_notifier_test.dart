import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_submission.dart';
import 'package:fraya_mobile/domain/repositories/driver_kyc_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/kyc/update_driver_kyc_usecase.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/kyc/providers/driver_kyc_dependencies.dart';
import 'package:fraya_mobile/features/driver/profile/providers/driver_kyc_update_dependencies.dart';
import 'package:fraya_mobile/features/driver/profile/providers/driver_kyc_update_notifier.dart';
import 'package:fraya_mobile/features/driver/profile/providers/driver_kyc_update_state.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../support/driver_test_doubles.dart';
import '../../../../support/driver_document_preparation_test_double.dart';

class _RecordingKycRepository implements DriverKycRepository {
  Map<DriverKycDocumentType, DriverKycDocumentFile>? lastUpdateDocuments;
  Map<String, dynamic> updateResponse = const {
    'data': {'status': 'PENDING_VALIDATION'},
    'message': 'Documents en attente de validation.',
  };
  Object? error;

  @override
  Future<Map<String, dynamic>> updateKyc({
    required int kycId,
    required Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  }) async {
    lastUpdateDocuments = documents;
    if (error != null) throw error!;
    return updateResponse;
  }

  @override
  Future<Map<String, dynamic>> getKycBySidUser({required int sidUserId}) async {
    return const {'data': []};
  }

  @override
  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required DriverKycSubmission submission,
  }) async {
    return const {};
  }
}

class _RecordingAuthNotifier extends FakeDriverAuthNotifier {
  _RecordingAuthNotifier()
    : super(
        AuthState(
          status: AuthStatus.authenticated,
          userData: const {'driverId': 37, 'kycStatus': 'APPROVED'},
        ),
      );

  Map<String, dynamic>? lastUserDataPatch;

  @override
  Future<void> updateUserData(Map<String, dynamic> newData) async {
    lastUserDataPatch = newData;
    setTestState(state.copyWith(userData: {...?state.userData, ...newData}));
  }
}

void main() {
  group('DriverKycUpdateNotifier', () {
    test(
      'submits personal documents accepted by KYC update endpoint',
      () async {
        final repository = _RecordingKycRepository()
          ..error = const ValidationException(message: 'stop');
        final container = ProviderContainer(
          overrides: [
            updateDriverKycUseCaseProvider.overrideWithValue(
              UpdateDriverKycUseCase(repository),
            ),
            driverDocumentPreparationServiceProvider.overrideWithValue(
              PassthroughDriverDocumentPreparationService(),
            ),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(driverKycUpdateProvider.notifier);

        await notifier.setDocument(
          DriverKycDocumentType.photoFrontPermis,
          _image('front.png'),
        );
        await notifier.setDocument(
          DriverKycDocumentType.photoCasier,
          _image('casier.png'),
        );

        await notifier.submit(6);

        expect(repository.lastUpdateDocuments?.keys, [
          DriverKycDocumentType.photoFrontPermis,
          DriverKycDocumentType.photoCasier,
        ]);
      },
    );

    test('profile document update does not change global kyc status', () async {
      final repository = _RecordingKycRepository();
      final authNotifier = _RecordingAuthNotifier();
      final container = ProviderContainer(
        overrides: [
          updateDriverKycUseCaseProvider.overrideWithValue(
            UpdateDriverKycUseCase(repository),
          ),
          driverAuthProvider.overrideWith((ref) => authNotifier),
          driverDocumentPreparationServiceProvider.overrideWithValue(
            PassthroughDriverDocumentPreparationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(driverKycUpdateProvider.notifier);

      await notifier.setDocument(
        DriverKycDocumentType.photoFrontPermis,
        _image('front.png'),
      );

      await notifier.submit(6, mode: DriverKycUpdateMode.profileDocumentUpdate);

      final state = container.read(driverKycUpdateProvider);
      expect(authNotifier.lastUserDataPatch, isNull);
      expect(authNotifier.state.userData?['kycStatus'], 'APPROVED');
      expect(state.completion?.status, 'PENDING_VALIDATION');
      expect(state.completion?.message, 'Documents en attente de validation.');
    });

    test('onboarding correction still changes global kyc status', () async {
      final repository = _RecordingKycRepository();
      final authNotifier = _RecordingAuthNotifier();
      final container = ProviderContainer(
        overrides: [
          updateDriverKycUseCaseProvider.overrideWithValue(
            UpdateDriverKycUseCase(repository),
          ),
          driverAuthProvider.overrideWith((ref) => authNotifier),
          driverDocumentPreparationServiceProvider.overrideWithValue(
            PassthroughDriverDocumentPreparationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(driverKycUpdateProvider.notifier);

      await notifier.setDocument(
        DriverKycDocumentType.photoFrontPermis,
        _image('front.png'),
      );

      await notifier.submit(6);

      expect(authNotifier.lastUserDataPatch, {
        'kycStatus': 'PENDING_VALIDATION',
      });
      expect(authNotifier.state.userData?['kycStatus'], 'PENDING_VALIDATION');
      expect(authNotifier.refreshProfileCalls, 1);
    });

    test('submits vehicle documents when vehicle group is selected', () async {
      final repository = _RecordingKycRepository();
      final authNotifier = _RecordingAuthNotifier();
      final container = ProviderContainer(
        overrides: [
          updateDriverKycUseCaseProvider.overrideWithValue(
            UpdateDriverKycUseCase(repository),
          ),
          driverAuthProvider.overrideWith((ref) => authNotifier),
          driverDocumentPreparationServiceProvider.overrideWithValue(
            PassthroughDriverDocumentPreparationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(driverKycUpdateProvider.notifier);

      await notifier.setDocument(
        DriverKycDocumentType.photoFrontPermis,
        _image('front-permis.png'),
      );
      await notifier.setDocument(
        DriverKycDocumentType.insuranceCertificate,
        _image('insurance.png'),
      );
      await notifier.setDocument(
        DriverKycDocumentType.vehicleRegistration,
        _image('registration.png'),
      );

      await notifier.submit(
        6,
        documentGroup: DriverKycUpdateDocumentGroup.vehicle,
      );

      expect(repository.lastUpdateDocuments?.keys, [
        DriverKycDocumentType.insuranceCertificate,
        DriverKycDocumentType.vehicleRegistration,
      ]);
      expect(authNotifier.lastUserDataPatch, {
        'kycStatus': 'PENDING_VALIDATION',
      });
      expect(authNotifier.refreshProfileCalls, 1);
    });

    test('canSubmit accepts criminal record document', () {
      final state = DriverKycUpdateState(
        selectedDocuments: {
          DriverKycDocumentType.photoCasier: _image('casier.png'),
        },
      );

      expect(state.canSubmit, isTrue);
    });

    test('canSubmitFor accepts vehicle documents', () {
      final state = DriverKycUpdateState(
        selectedDocuments: {
          DriverKycDocumentType.insuranceCertificate: _image('insurance.png'),
        },
      );

      expect(state.canSubmitFor(DriverKycUpdateDocumentGroup.vehicle), isTrue);
      expect(
        state.canSubmitFor(DriverKycUpdateDocumentGroup.personal),
        isFalse,
      );
    });
  });
}

DriverKycDocumentFile _image(String fileName) {
  return DriverKycDocumentFile.fromPath(
    path: '/tmp/$fileName',
    fileName: fileName,
    source: DriverKycDocumentSource.galleryImage,
  )!;
}
