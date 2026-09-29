library;

enum DeviceIssue {
  none,
  noInternet,
  locationServiceOff,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  probableAirplaneMode,
  serverUnreachable,
}

class DeviceStatusSnapshot {
  const DeviceStatusSnapshot({
    required this.issue,
    required this.title,
    required this.message,
    required this.checkedAt,
  });

  final DeviceIssue issue;
  final String title;
  final String message;
  final DateTime checkedAt;

  bool get hasIssue => issue != DeviceIssue.none;

  static DeviceStatusSnapshot initial() {
    return DeviceStatusSnapshot(
      issue: DeviceIssue.none,
      title: '',
      message: '',
      checkedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
