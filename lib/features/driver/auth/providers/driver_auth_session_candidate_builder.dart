library;

class DriverAuthSessionCandidateBuilder {
  static List<Map<String, dynamic>> buildCandidates(
    Map<String, dynamic> response,
  ) {
    final payload = extractPayload(response);
    final candidates = <Map<String, dynamic>>[];
    final payloadUser = payload['user'];
    if (payloadUser is Map) {
      candidates.add(Map<String, dynamic>.from(payloadUser));
    }

    final responseUser = response['user'];
    if (responseUser is Map) {
      candidates.add(Map<String, dynamic>.from(responseUser));
    }

    final payloadMap = stripAuthFields(payload);
    if (payloadMap.isNotEmpty) {
      candidates.add(payloadMap);
    }

    final responseMap = stripAuthFields(response);
    if (responseMap.isNotEmpty) {
      candidates.add(responseMap);
    }
    return candidates;
  }

  static Map<String, dynamic> extractPayload(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return Map<String, dynamic>.from(response);
  }

  static Map<String, dynamic> stripAuthFields(Map<String, dynamic> source) {
    final cleaned = Map<String, dynamic>.from(source);
    for (final key in const [
      'access_token',
      'accessToken',
      'refresh_token',
      'refreshToken',
      'token',
      'user',
      'data',
      'result',
    ]) {
      cleaned.remove(key);
    }
    return cleaned;
  }
}
