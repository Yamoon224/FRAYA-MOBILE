import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/repositories/passenger_profile_repository.dart';
import 'package:fraya_mobile/features/passenger/profile/models/profile_model.dart';
import 'package:fraya_mobile/features/passenger/profile/providers/profile_dependencies.dart';
import 'package:fraya_mobile/features/passenger/profile/widgets/profile_edit_dialog.dart';
import 'package:fraya_mobile/features/passenger/profile/widgets/profile_phone_change_dialog.dart';
import 'package:fraya_mobile/shared/widgets/confirmation_action_column.dart';

void main() {
  testWidgets('profile edit dialog follows stacked action convention', (
    tester,
  ) async {
    await _pumpDialog(tester, ProfileEditDialog(profile: _profile()));

    expect(find.byType(ConfirmationActionColumn), findsOneWidget);
    _expectAbove(tester, find.text('Enregistrer'), find.text('Annuler'));
  });

  testWidgets('phone change dialog follows stacked action convention', (
    tester,
  ) async {
    await _pumpDialog(tester, const ProfilePhoneChangeDialog());

    expect(find.byType(ConfirmationActionColumn), findsOneWidget);
    _expectAbove(tester, find.text('Envoyer le code'), find.text('Annuler'));
  });

  testWidgets('duplicate phone keeps first step open and does not show OTP', (
    tester,
  ) async {
    final repository = _ConflictPassengerProfileRepository();
    await _pumpDialog(
      tester,
      const ProfilePhoneChangeDialog(),
      repository: repository,
    );

    await tester.enterText(find.byType(TextFormField), '0707070708');
    await tester.tap(find.text('Envoyer le code'));
    await tester.pumpAndSettle();

    expect(repository.requestedPhoneNumbers, ['0707070708']);
    expect(repository.confirmationCodes, isEmpty);
    expect(find.text('Modifier le numéro'), findsOneWidget);
    expect(find.text('Vérification'), findsNothing);
    expect(
      find.text('Ce numéro de téléphone est déjà utilisé'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 10));
  });
}

Future<void> _pumpDialog(
  WidgetTester tester,
  Widget dialog, {
  PassengerProfileRepository? repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          profileRepositoryProvider.overrideWith((ref) => repository),
      ],
      child: MaterialApp(home: Scaffold(body: dialog)),
    ),
  );
  await tester.pumpAndSettle();
}

PassengerProfile _profile() {
  return PassengerProfile(
    firstName: 'Awa',
    lastName: 'Kone',
    name: 'Awa Kone',
    phone: '0700000000',
    email: 'awa@test.com',
    rating: null,
    ridesCount: null,
    membershipMonths: 0,
    memberSince: '',
  );
}

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}

class _ConflictPassengerProfileRepository
    implements PassengerProfileRepository {
  final requestedPhoneNumbers = <String>[];
  final confirmationCodes = <String>[];

  @override
  Future<void> requestPhoneChange(String newPhoneNumber) async {
    requestedPhoneNumbers.add(newPhoneNumber);
    throw const ServerException(
      message: 'Ce numéro de téléphone est déjà utilisé',
      statusCode: 409,
    );
  }

  @override
  Future<void> confirmPhoneChange(String verificationCode) async {
    confirmationCodes.add(verificationCode);
  }

  @override
  Future<Map<String, dynamic>> getProfile() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> updateProfilePhoto({
    required int userId,
    required String filePath,
    required String fileName,
  }) {
    throw UnimplementedError();
  }
}
