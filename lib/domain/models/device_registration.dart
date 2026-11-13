library;

import 'package:equatable/equatable.dart';

class DeviceRegistration extends Equatable {
  const DeviceRegistration({
    required this.userId,
    required this.role,
    required this.pushToken,
    required this.platform,
  });

  final String userId;
  final String role;
  final String pushToken;
  final String platform;

  /// Corps de POST /devices/register (le serveur déduit l'utilisateur du jeton d'authentification).
  Map<String, dynamic> toRegisterRequest() {
    return {'token': pushToken, 'platform': platform, 'role': role};
  }

  /// Corps de POST /devices/deactivate.
  Map<String, dynamic> toDeactivateRequest() {
    return {'token': pushToken};
  }

  /// Sérialisation locale (dernier enregistrement), qui garde aussi l'utilisateur.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'token': pushToken,
      'platform': platform,
    };
  }

  static DeviceRegistration? fromJson(Map<String, dynamic> json) {
    final userId = json['userId']?.toString().trim();
    final role = json['role']?.toString().trim();
    final pushToken = json['token']?.toString().trim();
    final platform = json['platform']?.toString().trim();

    if (userId == null ||
        userId.isEmpty ||
        role == null ||
        role.isEmpty ||
        pushToken == null ||
        pushToken.isEmpty ||
        platform == null ||
        platform.isEmpty) {
      return null;
    }

    return DeviceRegistration(
      userId: userId,
      role: role,
      pushToken: pushToken,
      platform: platform,
    );
  }

  @override
  List<Object?> get props => [userId, role, pushToken, platform];
}
