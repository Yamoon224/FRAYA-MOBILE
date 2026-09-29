import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_submission_review_info.dart';

void main() {
  group('DriverSubmissionReviewInfoResolver', () {
    test('extracts rejection reasons and ids from nested profile data', () {
      final info = DriverSubmissionReviewInfoResolver.fromUserData(const {
        'driverId': 14,
        'kycs': [
          {
            'id': '31',
            'status': 'REJECTED',
            'adminComment': 'Permis illisible.',
          },
        ],
        'vehicle': {
          'id': 7,
          'status': 'REJECTED',
          'rejectionReason': 'Carte grise expirée.',
          'brand': 'Toyota',
          'model': 'Corolla',
          'year': '2022',
          'color': 'Rouge',
          'licensePlate': 'AB-123-CD',
          'range': 'elite',
        },
      });

      expect(info.kycId, 31);
      expect(info.vehicleId, 7);
      expect(info.kycRejectionReason, 'Permis illisible.');
      expect(info.vehicleRejectionReason, 'Carte grise expirée.');
      expect(info.vehicle?.brand, 'Toyota');
      expect(info.vehicle?.range, 'elite');
    });

    test('uses KYC description as rejection reason', () {
      final info = DriverSubmissionReviewInfoResolver.fromUserData(const {
        'driverId': 37,
        'kycs': [
          {'id': 6, 'status': 'CANCEL', 'description': 'Permis non conformes'},
        ],
      });

      expect(info.kycId, 6);
      expect(info.kycRejectionReason, 'Permis non conformes');
    });
  });
}
