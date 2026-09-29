class RideShareLink {
  const RideShareLink({
    required this.token,
    required this.url,
    required this.expiresAt,
    required this.isValid,
  });

  factory RideShareLink.fromMap(Map<String, dynamic> map) {
    return RideShareLink(
      token: (map['token'] ?? '').toString().trim(),
      url: (map['url'] ?? '').toString().trim(),
      expiresAt: DateTime.tryParse((map['expiresAt'] ?? '').toString()),
      isValid: map['isValid'] == true,
    );
  }

  final String token;
  final String url;
  final DateTime? expiresAt;
  final bool isValid;
}
