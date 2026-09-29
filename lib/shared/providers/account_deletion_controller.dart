library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/constants.dart';
import '../../data/sources/local_storage.dart';
import '../../domain/models/auth_register_draft.dart';
import '../../domain/usecases/account/delete_account.dart';
import '../../features/driver/auth/providers/driver_auth_provider.dart';
import '../../features/driver/auth/providers/driver_register_flow_provider.dart';
import '../../features/driver/kyc/providers/driver_kyc_provider.dart';
import '../../features/driver/onboarding/providers/driver_onboarding_draft_dependencies.dart';
import '../../features/driver/vehicle/providers/driver_vehicle_form_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../features/passenger/booking/providers/pending_search_session_provider.dart';
import 'account_deletion_dependencies.dart';
import 'auth_register_draft_provider.dart';

class AccountDeletionState {
  const AccountDeletionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final bool success;
}

final accountDeletionControllerProvider =
    NotifierProvider<AccountDeletionController, AccountDeletionState>(
      AccountDeletionController.new,
      isAutoDispose: true,
    );

class AccountDeletionController extends Notifier<AccountDeletionState> {
  @override
  AccountDeletionState build() => const AccountDeletionState();

  Future<bool> deletePassengerAccount() async {
    final userId = _readUserId(ref.read(passengerAuthProvider).userData);
    if (!_startDeletion(userId)) return false;

    await ref
        .read(pendingSearchCleanupControllerProvider)
        .cancelPendingSearch(
          reason: 'Suppression du compte passager',
          clearOnFailure: true,
        );
    return _deleteAccount(
      userId!,
      onSuccess: () {
        return ref.read(passengerAuthProvider.notifier).logout();
      },
    );
  }

  Future<bool> deleteDriverAccount() async {
    final userId = _readUserId(ref.read(driverAuthProvider).userData);
    if (!_startDeletion(userId)) return false;

    return _deleteAccount(
      userId!,
      onSuccess: () {
        return _clearDriverLocalDataAndLogout(userId);
      },
    );
  }

  void clearFeedback() {
    state = const AccountDeletionState();
  }

  bool _startDeletion(int? userId) {
    if (state.isSubmitting) return false;
    if (userId == null) {
      state = const AccountDeletionState(
        errorMessage: "Impossible d'identifier le compte à supprimer.",
      );
      return false;
    }
    state = const AccountDeletionState(isSubmitting: true);
    return true;
  }

  Future<bool> _deleteAccount(
    int userId, {
    required Future<void> Function() onSuccess,
  }) async {
    final result = await ref.read(deleteAccountUseCaseProvider)(
      DeleteAccountParams(userId: userId),
    );
    return result.fold<Future<bool>>(
      (failure) async {
        state = AccountDeletionState(errorMessage: failure.message);
        return false;
      },
      (_) async {
        state = const AccountDeletionState(success: true);
        await onSuccess();
        return true;
      },
    );
  }

  Future<void> _clearDriverLocalDataAndLogout(int userId) async {
    try {
      await _clearDriverAccountData(userId);
    } finally {
      await ref.read(driverAuthProvider.notifier).logout();
      _invalidateDriverRegistrationState();
    }
  }

  Future<void> _clearDriverAccountData(int userId) async {
    await ref
        .read(authRegisterDraftRepositoryProvider)
        .clearDraft(AuthRegisterRole.driver);
    await ref.read(driverOnboardingDraftRepositoryProvider).clearDraft();

    final storage = LocalStorage.instance;
    await storage.remove('driver_is_online_$userId');
    await storage.remove(
      '${AppConstants.driverIgnoredRideIdsKeyPrefix}$userId',
    );
    await storage.remove(AppConstants.driverWalletCommissionNoticeDismissedKey);
  }

  void _invalidateDriverRegistrationState() {
    ref.invalidate(driverRegisterFlowProvider);
    ref.invalidate(driverKycFormProvider);
    ref.invalidate(driverVehicleFormProvider);
  }

  int? _readUserId(Map<String, dynamic>? userData) {
    final raw =
        userData?['id'] ??
        userData?['userId'] ??
        userData?['SID'] ??
        userData?['sub'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}
