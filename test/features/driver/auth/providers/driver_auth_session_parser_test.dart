import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_session_parser.dart';

void main() {
  group('DriverAuthSessionParser', () {
    test('extracts token driverId and vehicleId from auth payload', () {
      final response = <String, dynamic>{
        'data': {
          'access_token': 'driver-token',
          'user': {
            'id': 9,
            'phoneNumber': '0700000000',
            'vehicle': {'id': 17},
          },
        },
      };

      final token = DriverAuthSessionParser.extractToken(response);
      final userData = DriverAuthSessionParser.buildUserData(response);

      expect(token, 'driver-token');
      expect(userData?['driverId'], 9);
      expect(userData?['userId'], 9);
      expect(userData?['vehicleId'], 17);
      expect(userData?['phoneNumber'], '0700000000');
      expect(userData?['kycStatus'], 'NOT_SUBMITTED');
      expect(userData?['vehicleStatus'], 'NOT_SUBMITTED');
    });

    test('normalizes stored user data with sub and nested vehicle', () {
      final storedUserData = <String, dynamic>{
        'sub': '24',
        'vehicle': {'id': '5', 'vehicleStatus': 'validated'},
        'kyc': {'status': 'pending'},
        'firstNames': 'Moussa',
      };

      final userData = DriverAuthSessionParser.normalizeStoredUserData(
        storedUserData,
      );

      expect(userData?['driverId'], 24);
      expect(userData?['userId'], 24);
      expect(userData?['id'], 24);
      expect(userData?['vehicleId'], 5);
      expect(userData?['kycStatus'], 'PENDING_VALIDATION');
      expect(userData?['vehicleStatus'], 'APPROVED');
      expect(userData?['firstNames'], 'Moussa');
    });

    test('keeps sid user id separate from driver id when both exist', () {
      final response = <String, dynamic>{
        'data': {
          'user': {
            'id': 24,
            'driverId': 14,
            'vehicle': {'id': 7},
          },
        },
      };

      final userData = DriverAuthSessionParser.buildUserData(response);

      expect(userData?['userId'], 24);
      expect(userData?['driverId'], 14);
      expect(userData?['id'], 24);
      expect(userData?['vehicleId'], 7);
    });

    test('extracts vehicle session patch from vehicle creation response', () {
      final response = <String, dynamic>{
        'data': {'id': 41, 'vehicleStatus': 'validated'},
      };

      final patch = DriverAuthSessionParser.extractVehicleSessionPatch(
        response,
      );

      expect(patch?['vehicleId'], 41);
      expect(patch?['vehicleStatus'], 'APPROVED');
    });

    test(
      'defaults vehicle status to pending when missing in creation response',
      () {
        final response = <String, dynamic>{
          'data': {
            'vehicle': {'id': '8'},
          },
        };

        final patch = DriverAuthSessionParser.extractVehicleSessionPatch(
          response,
        );

        expect(patch?['vehicleId'], 8);
        expect(patch?['vehicleStatus'], 'PENDING_VALIDATION');
      },
    );

    test('maps canceled KYC status to rejected', () {
      final userData = DriverAuthSessionParser.buildUserData(const {
        'data': {
          'id': 37,
          'kycs': [
            {'id': 6, 'status': 'CANCEL'},
          ],
        },
      });

      expect(userData?['kycStatus'], 'REJECTED');
    });
  });
}
