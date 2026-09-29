import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local/auth_register_draft_local_data_source.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRegisterDraftLocalDataSource', () {
    late AuthRegisterDraftLocalDataSource dataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorage.instance.init();
      dataSource = AuthRegisterDraftLocalDataSource();
    });

    test('keeps passenger and driver drafts isolated', () async {
      await dataSource.saveDraft(
        AuthRegisterDraft(
          role: AuthRegisterRole.passenger,
          step: AuthRegisterFlowStep.otp,
          phoneNumber: '0700000000',
          updatedAt: DateTime(2026, 7, 2),
        ),
      );
      await dataSource.saveDraft(
        AuthRegisterDraft(
          role: AuthRegisterRole.driver,
          step: AuthRegisterFlowStep.details,
          phoneNumber: '0100000000',
          email: 'driver@example.com',
          updatedAt: DateTime(2026, 7, 2),
        ),
      );

      final passenger = await dataSource.readDraft(AuthRegisterRole.passenger);
      final driver = await dataSource.readDraft(AuthRegisterRole.driver);

      expect(passenger?.phoneNumber, '0700000000');
      expect(passenger?.email, isNull);
      expect(driver?.phoneNumber, '0100000000');
      expect(driver?.email, 'driver@example.com');

      await dataSource.clearDraft(AuthRegisterRole.driver);

      expect(await dataSource.readDraft(AuthRegisterRole.driver), isNull);
      expect(await dataSource.readDraft(AuthRegisterRole.passenger), isNotNull);
    });

    test('removes a legacy draft without schema version', () async {
      await LocalStorage.instance.setString(
        AppConstants.passengerRegisterDraftKey,
        jsonEncode({
          'role': AuthRegisterRole.passenger.name,
          'step': AuthRegisterFlowStep.details.name,
          'phoneNumber': '0700000000',
          'updatedAt': DateTime(2026, 7, 2).toIso8601String(),
        }),
      );

      final draft = await dataSource.readDraft(AuthRegisterRole.passenger);

      expect(draft, isNull);
      expect(
        LocalStorage.instance.getString(AppConstants.passengerRegisterDraftKey),
        isNull,
      );
    });

    test('restores newly versioned drafts for both roles', () async {
      for (final role in AuthRegisterRole.values) {
        await dataSource.saveDraft(
          AuthRegisterDraft(
            role: role,
            step: AuthRegisterFlowStep.otp,
            phoneNumber: role == AuthRegisterRole.passenger
                ? '0700000000'
                : '0100000000',
            updatedAt: DateTime(2026, 7, 16),
          ),
        );
      }

      final passenger = await dataSource.readDraft(AuthRegisterRole.passenger);
      final driver = await dataSource.readDraft(AuthRegisterRole.driver);

      expect(passenger?.phoneNumber, '0700000000');
      expect(driver?.phoneNumber, '0100000000');
    });
  });
}
