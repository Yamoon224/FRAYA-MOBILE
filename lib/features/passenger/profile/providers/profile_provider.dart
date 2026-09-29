import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/usecases/passenger/profile/change_passenger_phone.dart';
import '../../../../domain/usecases/passenger/profile/update_passenger_profile.dart';
import '../../../../domain/usecases/passenger/profile/update_passenger_profile_photo.dart';
import '../../auth/providers/passenger_auth_provider.dart';
import '../../booking/providers/pending_search_session_provider.dart';
import '../models/profile_model.dart';
import 'profile_dependencies.dart';

final _log = AppLogger.instance;

class ProfileUpdateState {
  const ProfileUpdateState({
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

final passengerProfileProvider = FutureProvider.autoDispose<PassengerProfile>((
  ref,
) async {
  final authState = ref.watch(passengerAuthProvider);
  final userData = authState.userData;
  if (userData == null) return PassengerProfile.empty();

  final getProfile = ref.read(getPassengerProfileUseCaseProvider);
  final result = await getProfile();
  return result.fold((failure) {
    _log.warning(
      'Echec chargement profil API, usage local: ${failure.message}',
    );
    return PassengerProfile.fromMap(userData);
  }, PassengerProfile.fromMap);
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileUpdateState>(
      ProfileController.new,
      isAutoDispose: true,
    );

class ProfileController extends Notifier<ProfileUpdateState> {
  @override
  ProfileUpdateState build() => const ProfileUpdateState();

  String? get errorMessage => state.errorMessage;

  Future<void> logout() async {
    await ref
        .read(pendingSearchCleanupControllerProvider)
        .cancelPendingSearchBeforeLogout();
    await ref.read(passengerAuthProvider.notifier).logout();
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    if (state.isSubmitting) return;

    final userId = _parseUserId(ref.read(passengerAuthProvider).userData);
    final payload = _buildUpdatePayload(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    if (userId == null || payload.isEmpty) return;

    state = const ProfileUpdateState(isSubmitting: true);
    try {
      final result = await ref.read(updatePassengerProfileUseCaseProvider)(
        UpdatePassengerProfileParams(userId: userId, data: payload),
      );
      await result.fold(
        (failure) async {
          _log.error('Erreur updateProfile: ${failure.message}');
          state = ProfileUpdateState(errorMessage: failure.message);
        },
        (response) async {
          await _syncLocalProfile(response, fallbackData: payload);
          state = const ProfileUpdateState(success: true);
        },
      );
    } catch (e) {
      state = ProfileUpdateState(errorMessage: 'Erreur: $e');
    }
  }

  Future<void> updateProfilePhoto({
    required String filePath,
    required String fileName,
  }) async {
    if (state.isSubmitting) return;

    final userId = _parseUserId(ref.read(passengerAuthProvider).userData);
    if (userId == null) return;

    state = const ProfileUpdateState(isSubmitting: true);
    try {
      final result = await ref.read(updatePassengerProfilePhotoUseCaseProvider)(
        UpdatePassengerProfilePhotoParams(
          userId: userId,
          filePath: filePath,
          fileName: fileName,
        ),
      );
      await result.fold(
        (failure) async {
          _log.error('Erreur updateProfilePhoto: ${failure.message}');
          state = ProfileUpdateState(errorMessage: failure.message);
        },
        (response) async {
          final photoPatch = _extractPhotoPatch(response);
          await _refreshLocalProfile(fallbackData: photoPatch);
          state = const ProfileUpdateState(success: true);
        },
      );
    } catch (e) {
      state = ProfileUpdateState(errorMessage: 'Erreur: $e');
    }
  }

  Future<void> requestPhoneChange(String newPhoneNumber) async {
    if (state.isSubmitting) return;
    state = const ProfileUpdateState(isSubmitting: true);
    try {
      final result = await ref.read(sendPhoneChangeOtpUseCaseProvider)(
        newPhoneNumber,
      );
      result.fold(
        (failure) => state = ProfileUpdateState(
          errorMessage: failure.message,
          errorStatusCode: failure is ServerFailure ? failure.statusCode : null,
        ),
        (_) => state = const ProfileUpdateState(success: true),
      );
    } catch (e) {
      state = ProfileUpdateState(errorMessage: 'Erreur: $e');
    }
  }

  Future<void> changePhone(String phoneNumber, String otp) async {
    if (state.isSubmitting) return;

    state = const ProfileUpdateState(isSubmitting: true);
    try {
      final result = await ref.read(changePassengerPhoneUseCaseProvider)(
        ChangePassengerPhoneParams(otp: otp),
      );
      await result.fold(
        (failure) async {
          state = ProfileUpdateState(
            errorMessage: failure.message,
            errorStatusCode: failure is ServerFailure
                ? failure.statusCode
                : null,
          );
        },
        (_) async {
          await ref.read(passengerAuthProvider.notifier).updateUserData({
            'phoneNumber': phoneNumber,
          });
          ref.invalidate(passengerProfileProvider);
          state = const ProfileUpdateState(success: true);
        },
      );
    } catch (e) {
      state = ProfileUpdateState(errorMessage: 'Erreur: $e');
    }
  }

  void clearFeedback() {
    state = const ProfileUpdateState();
  }

  int? _parseUserId(Map<String, dynamic>? userData) {
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

  Map<String, dynamic> _buildUpdatePayload({
    String? firstName,
    String? lastName,
    String? email,
  }) {
    final payload = <String, dynamic>{};
    final trimmedFirst = firstName?.trim() ?? '';
    final trimmedLast = lastName?.trim() ?? '';
    final trimmedEmail = email?.trim() ?? '';
    if (trimmedFirst.isNotEmpty) payload['firstNames'] = trimmedFirst;
    if (trimmedLast.isNotEmpty) payload['lastName'] = trimmedLast;
    if (trimmedEmail.isNotEmpty) payload['email'] = trimmedEmail;
    return payload;
  }

  Future<void> _syncLocalProfile(
    Map<String, dynamic> response, {
    required Map<String, dynamic> fallbackData,
  }) async {
    final userPatch = _extractUserPatch(response);
    final mergedPatch = <String, dynamic>{...fallbackData, ...userPatch};
    if (mergedPatch.isNotEmpty) {
      await ref
          .read(passengerAuthProvider.notifier)
          .updateUserData(mergedPatch);
    }
    ref.invalidate(passengerProfileProvider);
  }

  Future<void> _refreshLocalProfile({
    required Map<String, dynamic> fallbackData,
  }) async {
    final result = await ref.read(getPassengerProfileUseCaseProvider)();
    await result.fold(
      (_) => _syncLocalProfile(const {}, fallbackData: fallbackData),
      (profile) => _syncLocalProfile(profile, fallbackData: fallbackData),
    );
  }

  Map<String, dynamic> _extractUserPatch(Map<String, dynamic> response) {
    final extracted = _unwrapResponse(response);
    if (extracted is Map<String, dynamic>) return extracted;
    if (extracted is Map) return Map<String, dynamic>.from(extracted);
    return const {};
  }

  Map<String, dynamic> _extractPhotoPatch(Map<String, dynamic> response) {
    final patch = _extractUserPatch(response);
    final value = patch['profilePhoto'] ?? response['profilePhoto'];
    if (value is String && value.trim().isNotEmpty) {
      return {'profilePhoto': value.trim()};
    }
    return const {};
  }

  dynamic _unwrapResponse(dynamic data) {
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
    return current;
  }
}
