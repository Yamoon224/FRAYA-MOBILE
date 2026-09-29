import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_local_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DriverAuthLocalSession session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LocalStorage.instance.init();
    session = DriverAuthLocalSession();
  });

  test('restores only the dedicated driver keys', () async {
    await LocalStorage.instance.setSecure(
      AppConstants.driverAccessTokenKey,
      'driver-token',
    );
    await LocalStorage.instance.setSecure(
      AppConstants.driverAuthUserDataKey,
      jsonEncode({
        'driverId': 14,
        'vehicleId': 7,
        'kycStatus': 'APPROVED',
        'vehicleStatus': 'APPROVED',
      }),
    );

    final restored = await session.restore();

    expect(restored?['driverId'], 14);
    expect(restored?['vehicleId'], 7);
    expect(restored?['kycStatus'], 'APPROVED');
  });

  test('returns null when the dedicated driver keys are missing', () async {
    final restored = await session.restore();

    expect(restored, isNull);
  });

  test(
    'throws a controlled format error when stored user data is invalid',
    () async {
      await LocalStorage.instance.setSecure(
        AppConstants.driverAccessTokenKey,
        'driver-token',
      );
      await LocalStorage.instance.setSecure(
        AppConstants.driverAuthUserDataKey,
        jsonEncode(['invalid']),
      );

      expect(session.restore, throwsFormatException);
    },
  );

  test('ignores passenger secure keys when driver keys are absent', () async {
    await LocalStorage.instance.setSecure(
      AppConstants.accessTokenKey,
      'passenger-token',
    );
    await LocalStorage.instance.setSecure(
      AppConstants.authUserDataKey,
      jsonEncode({'id': 9, 'firstNames': 'Passenger'}),
    );

    final restored = await session.restore();

    expect(restored, isNull);
    expect(
      await LocalStorage.instance.getSecure(AppConstants.accessTokenKey),
      'passenger-token',
    );
  });

  test(
    'updates the driver session without overwriting passenger secure keys',
    () async {
      await LocalStorage.instance.setSecure(
        AppConstants.accessTokenKey,
        'passenger-token',
      );
      await LocalStorage.instance.setSecure(
        AppConstants.authUserDataKey,
        jsonEncode({'id': 77, 'firstNames': 'Passenger'}),
      );
      await session.persist('driver-token', {
        'driverId': 14,
        'vehicleId': 7,
        'kycStatus': 'PENDING',
        'vehicleStatus': 'NOT_SUBMITTED',
      });

      final updated = await session.update(
        {
          'driverId': 14,
          'vehicleId': 7,
          'kycStatus': 'PENDING',
          'vehicleStatus': 'NOT_SUBMITTED',
        },
        {'vehicleStatus': 'APPROVED'},
      );

      expect(updated?['vehicleStatus'], 'APPROVED');
      expect(
        await LocalStorage.instance.getSecure(AppConstants.accessTokenKey),
        'passenger-token',
      );
      expect(
        await LocalStorage.instance.getSecure(AppConstants.authUserDataKey),
        jsonEncode({'id': 77, 'firstNames': 'Passenger'}),
      );
    },
  );

  test(
    'preserves approved kyc status when refreshed profile omits kyc data',
    () async {
      final merged = await session.mergeProfile(
        const {
          'driverId': 14,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
        },
        const {
          'data': {'id': 14, 'firstNames': 'Moussa'},
        },
      );

      expect(merged?['kycStatus'], 'APPROVED');
      expect(merged?['firstNames'], 'Moussa');
    },
  );

  test(
    'preserves approved vehicle status when refreshed profile omits vehicle status',
    () async {
      final merged = await session.mergeProfile(
        const {
          'driverId': 14,
          'vehicleId': 7,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
        },
        const {
          'data': {
            'id': 14,
            'vehicle': {'id': 7},
          },
        },
      );

      expect(merged?['vehicleStatus'], 'APPROVED');
      expect(merged?['vehicleId'], 7);
    },
  );

  test(
    'replaces statuses when refreshed profile provides explicit values',
    () async {
      final merged = await session.mergeProfile(
        const {
          'driverId': 14,
          'vehicleId': 7,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
        },
        const {
          'data': {
            'id': 14,
            'kycStatus': 'REJECTED',
            'vehicleStatus': 'PENDING_VALIDATION',
            'vehicle': {'id': 7, 'vehicleStatus': 'PENDING_VALIDATION'},
          },
        },
      );

      expect(merged?['kycStatus'], 'REJECTED');
      expect(merged?['vehicleStatus'], 'PENDING_VALIDATION');
    },
  );

  test(
    'keeps explicit backend not submitted status instead of restoring old value',
    () async {
      final merged = await session.mergeProfile(
        const {
          'driverId': 14,
          'vehicleId': 7,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
        },
        const {
          'data': {
            'id': 14,
            'kycStatus': 'NOT_SUBMITTED',
            'vehicleStatus': 'NOT_SUBMITTED',
          },
        },
      );

      expect(merged?['kycStatus'], 'NOT_SUBMITTED');
      expect(merged?['vehicleStatus'], 'NOT_SUBMITTED');
    },
  );
}
