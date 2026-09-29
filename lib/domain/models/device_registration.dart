library;

import 'package:equatable/equatable.dart';

class DeviceRegistration extends Equatable {
  const DeviceRegistration({
    required this.userId,
    required this.role,
    required this.oneSignalSubscriptionId,
    required this.platform,
  });

  final String userId;
  final String role;
  final String oneSignalSubscriptionId;
  final String platform;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'oneSignalSubscriptionId': oneSignalSubscriptionId,
      'platform': platform,
    };
  }

  static DeviceRegistration? fromJson(Map<String, dynamic> json) {
    final userId = json['userId']?.toString().trim();
    final role = json['role']?.toString().trim();
    final oneSignalSubscriptionId = json['oneSignalSubscriptionId']
        ?.toString()
        .trim();
    final platform = json['platform']?.toString().trim();

    if (userId == null ||
        userId.isEmpty ||
        role == null ||
        role.isEmpty ||
        oneSignalSubscriptionId == null ||
        oneSignalSubscriptionId.isEmpty ||
        platform == null ||
        platform.isEmpty) {
      return null;
    }

    return DeviceRegistration(
      userId: userId,
      role: role,
      oneSignalSubscriptionId: oneSignalSubscriptionId,
      platform: platform,
    );
  }

  @override
  List<Object?> get props => [userId, role, oneSignalSubscriptionId, platform];
}
