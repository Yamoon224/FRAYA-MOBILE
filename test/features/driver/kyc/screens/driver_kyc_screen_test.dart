import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_submission.dart';
import 'package:fraya_mobile/domain/models/driver_onboarding_draft.dart';
import 'package:fraya_mobile/domain/repositories/driver_kyc_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_onboarding_draft_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/kyc/submit_driver_kyc_usecase.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/kyc/providers/driver_kyc_dependencies.dart';
import 'package:fraya_mobile/features/driver/kyc/screens/driver_kyc_screen.dart';
import 'package:fraya_mobile/features/driver/onboarding/providers/driver_onboarding_draft_dependencies.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  testWidgets('renders only driver documents on the KYC screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverAuthProvider.overrideWith(
            (ref) => FakeDriverAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                userData: const {'driverId': 14, 'kycStatus': 'NOT_SUBMITTED'},
              ),
            ),
          ),
          driverOnboardingDraftRepositoryProvider.overrideWithValue(
            _NoopDraftRepository(),
          ),
          submitDriverKycUseCaseProvider.overrideWithValue(
            SubmitDriverKycUseCase(_NoopKycRepository()),
          ),
        ],
        child: const MaterialApp(home: DriverKycScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Documents chauffeur'), findsOneWidget);
    expect(find.text('Documents liés au véhicule'), findsNothing);
    expect(find.text('Assurance véhicule'), findsNothing);
    expect(find.text('Carte grise'), findsNothing);
    expect(find.text('Casier judiciaire (optionnel)'), findsOneWidget);
    expect(
      find.textContaining('dans les 3 mois suivant votre inscription'),
      findsOneWidget,
    );
  });
}

class _NoopKycRepository implements DriverKycRepository {
  @override
  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required DriverKycSubmission submission,
  }) async {
    return const {};
  }

  @override
  Future<Map<String, dynamic>> updateKyc({
    required int kycId,
    required Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  }) async {
    return const {};
  }

  @override
  Future<Map<String, dynamic>> getKycBySidUser({required int sidUserId}) async {
    return const {'data': []};
  }
}

class _NoopDraftRepository implements DriverOnboardingDraftRepository {
  @override
  Future<void> clearDraft() async {}

  @override
  Future<bool> documentExists(String path) async => false;

  @override
  Future<DriverKycDocumentFile> persistDocument(
    DriverKycDocumentFile file, {
    required String namespace,
  }) async {
    return file;
  }

  @override
  Future<DriverOnboardingDraft?> readDraft() async => null;

  @override
  Future<void> removePersistedDocument(String path) async {}

  @override
  Future<void> saveDraft(DriverOnboardingDraft draft) async {}
}
