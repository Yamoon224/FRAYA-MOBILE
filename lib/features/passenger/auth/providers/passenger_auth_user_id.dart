int? passengerAuthUserIdFromData(Map<String, dynamic>? userData) {
  if (userData == null) return null;

  final raw = userData['id'] ?? userData['userId'] ?? userData['SID'] ?? userData['sub'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
}
