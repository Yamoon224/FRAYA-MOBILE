import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_admin_status_gate.dart';

void main() {
  group('DriverAdminStatusGate', () {
    test('requires KYC when status is not submitted', () {
      final result = DriverAdminStatusGate.fromUserData(const {
        'kycStatus': 'NOT_SUBMITTED',
        'vehicleStatus': 'NOT_SUBMITTED',
      });

      expect(result.needsKycSubmission, isTrue);
      expect(result.canGoOnline, isFalse);
    });

    test('allows online only when kyc and vehicle are approved', () {
      final result = DriverAdminStatusGate.fromUserData(const {
        'kycStatus': 'APPROVED',
        'vehicleStatus': 'APPROVED',
        'vehicleId': 7,
      });

      expect(result.isKycApproved, isTrue);
      expect(result.canGoOnline, isTrue);
    });

    test('keeps driver blocked while kyc validation is pending', () {
      final result = DriverAdminStatusGate.fromUserData(const {
        'kycStatus': 'PENDING_VALIDATION',
        'vehicleStatus': 'NOT_SUBMITTED',
      });

      expect(result.isKycPending, isTrue);
      expect(result.needsKycSubmission, isFalse);
      expect(result.canGoOnline, isFalse);
      expect(
        result.blockingMessage,
        'Votre dossier KYC est en attente de validation par un administrateur.',
      );
    });
  });
}
