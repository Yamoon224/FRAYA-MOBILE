library;

enum TopAlertSeverity { error, warning, info, success }

enum TopAlertSource { deviceStatus }

class TopAlertItem {
  const TopAlertItem({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final TopAlertSeverity severity;
  final String title;
  final String message;
  final TopAlertSource source;
  final DateTime createdAt;

  TopAlertItem copyWith({
    TopAlertSeverity? severity,
    String? title,
    String? message,
    DateTime? createdAt,
  }) {
    return TopAlertItem(
      id: id,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      source: source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
