library;

class DriverAuthSessionStatusNormalizer {
  static String normalize(String? rawStatus) {
    final normalized = rawStatus?.trim().toUpperCase().replaceAll('-', '_');
    if (normalized == null || normalized.isEmpty) {
      return 'NOT_SUBMITTED';
    }
    if (const {'APPROVED', 'VALIDATED', 'ACTIVE'}.contains(normalized)) {
      return 'APPROVED';
    }
    if (const {
      'PENDING_VALIDATION',
      'PENDING',
      'UNDER_REVIEW',
      'SUBMITTED',
    }.contains(normalized)) {
      return 'PENDING_VALIDATION';
    }
    if (const {
      'REJECTED',
      'REFUSED',
      'CANCEL',
      'CANCELED',
      'CANCELLED',
    }.contains(normalized)) {
      return 'REJECTED';
    }
    return normalized;
  }
}
