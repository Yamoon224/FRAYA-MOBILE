import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/usecases/driver/profile/change_driver_phone.dart';
import '../../../../domain/usecases/driver/profile/update_driver_profile.dart';
import '../../../../domain/usecases/driver/profile/update_driver_profile_photo.dart';
import '../../auth/providers/driver_auth_provider.dart';
import 'driver_profile_dependencies.dart';

final _log = AppLogger.instance;

class DriverProfileUpdateState {
  const DriverProfileUpdateState({
    this.isSubmitting = false,
    this.errorMessage,
    this.errorStatusCode,
    this.success = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final int? errorStatusCode;
  final bool success;
}

final driverProfileControllerProvider =
    NotifierProvider<DriverProfileController, DriverProfileUpdateState>(
      DriverProfileController.new,
      isAutoDispose: true,
    );

class DriverProfileController extends Notifier<DriverProfileUpdateState> {
  @override
  DriverProfileUpdateState build() => const DriverProfileUpdateState();

  String? get errorMessage => state.errorMessage;

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    if (state.isSubmitting) return;
    final userId = _parseUserId();
    final payload = _buildPayload(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    if (userId == null || payload.isEmpty) return;

    state = const DriverProfileUpdateState(isSubmitting: true);
    try {
      final result = await ref.read(updateDriverProfileUseCaseProvider)(
        UpdateDriverProfileParams(userId: userId, data: payload),
      );
      await result.fold(
        (failure) async {
          _log.error('Erreur updateProfile driver: ${failure.message}');
          state = DriverProfileUpdateState(errorMessage: failure.message);
        },
        (response) async {
          await _syncUserData(response, fallback: payload);
          state = const DriverProfileUpdateState(success: true);
        },
      );
    } catch (e) {
      state = DriverProfileUpdateState(errorMessage: 'Erreur: $e');
    }
  }

  Future<void> updateProfilePhoto({
    required String filePath,
    required String fileName,
  }) async {
    if (state.isSubmitting) return;
    final userId = _parseUserId();
    if (userId == null) return;

    state = const DriverProfileUpdateState(isSubmitting: true);
    try {
      final result = await ref.read(updateDriverProfilePhotoUseCaseProvider)(
        UpdateDriverProfilePhotoParams(
          userId: userId,
          filePath: filePath,
          fileName: fileName,
        ),
      );
      await result.fold(
        (failure) async {
          _log.error('Erreur updateProfilePhoto driver: ${failure.message}');
          state = DriverProfileUpdateState(errorMessage: failure.message);
        },
        (response) async {
          final patch = _extractPhotoPatch(response);
          if (patch.isNotEmpty) {
            await _syncUserData(response, fallback: patch);
          }
          await ref.read(driverAuthProvider.notifier).refreshProfile();
          state = const DriverProfileUpdateState(success: true);
        },
      );
    } catch (e) {
      state = DriverProfileUpdateState(errorMessage: 'Erreur: $e');
    }
  }

  Future<void> requestPhoneChange(String newPhoneNumber) async {
    if (state.isSubmitting) return;
    state = const DriverProfileUpdateState(isSubmitting: true);
    try {
      final result = await ref.read(sendDriverPhoneChangeOtpUseCaseProvider)(
        newPhoneNumber,
      );
      result.fold(
        (failure) => state = DriverProfileUpdateState(
          errorMessage: failure.message,
          errorStatusCode: failure is ServerFailure ? failure.statusCode : null,
        ),
        (_) => state = const DriverProfileUpdateState(success: true),
      );
    } catch (e) {
      state = DriverProfileUpdateState(errorMessage: 'Erreur: $e');
    }
  }

  Future<void> changePhone(String phoneNumber, String otp) async {
    if (state.isSubmitting) return;

    state = const DriverProfileUpdateState(isSubmitting: true);
    try {
      final result = await ref.read(changeDriverPhoneUseCaseProvider)(
        ChangeDriverPhoneParams(otp: otp),
      );
      await result.fold(
        (failure) async {
          state = DriverProfileUpdateState(
            errorMessage: failure.message,
            errorStatusCode: failure is ServerFailure
                ? failure.statusCode
                : null,
          );
        },
        (_) async {
          await ref.read(driverAuthProvider.notifier).updateUserData({
            'phoneNumber': phoneNumber,
          });
          state = const DriverProfileUpdateState(success: true);
        },
      );
    } catch (e) {
      state = DriverProfileUpdateState(errorMessage: 'Erreur: $e');
    }
  }

  void clearFeedback() => state = const DriverProfileUpdateState();

  int? _parseUserId() {
    final userData = ref.read(driverAuthProvider).userData;
    if (userData == null) return null;
    final raw =
        userData['id'] ??
        userData['userId'] ??
        userData['SID'] ??
        userData['sub'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  Map<String, dynamic> _buildPayload({
    String? firstName,
    String? lastName,
    String? email,
  }) {
    final payload = <String, dynamic>{};
    if ((firstName ?? '').trim().isNotEmpty) {
      payload['firstNames'] = firstName!.trim();
    }
    if ((lastName ?? '').trim().isNotEmpty) {
      payload['lastName'] = lastName!.trim();
    }
    if ((email ?? '').trim().isNotEmpty) {
      payload['email'] = email!.trim();
    }
    return payload;
  }

  Future<void> _syncUserData(
    Map<String, dynamic> response, {
    required Map<String, dynamic> fallback,
  }) async {
    final patch = _unwrap(response);
    final merged = <String, dynamic>{...fallback, ...patch};
    if (merged.isNotEmpty) {
      await ref.read(driverAuthProvider.notifier).updateUserData(merged);
    }
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    var current = data;
    while (current is Map) {
      final next =
          current['data'] ??
          current['user'] ??
          current['result'] ??
          current['sidUser'];
      if (next == null || identical(next, current)) break;
      current = next;
    }
    if (current is Map<String, dynamic>) return current;
    if (current is Map) return Map<String, dynamic>.from(current);
    return const {};
  }

  Map<String, dynamic> _extractPhotoPatch(Map<String, dynamic> response) {
    final patch = _unwrap(response);
    final value = patch['profilePhoto'] ?? response['profilePhoto'];
    if (value is String && value.trim().isNotEmpty) {
      return {'profilePhoto': value.trim()};
    }
    return const {};
  }
}
