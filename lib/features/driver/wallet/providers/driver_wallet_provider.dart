library;

import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/models/driver_wallet_package.dart';
import '../../../../../domain/models/driver_wallet_reload_result.dart';
import '../../../../../domain/models/orange_money_payment.dart';
import '../../../../../domain/usecases/driver/wallet/orange_money_reload_usecases.dart';
import '../../../../../domain/usecases/driver/wallet/get_driver_wallet_overview_usecase.dart';
import '../../../../../domain/usecases/driver/wallet/get_driver_wallet_packages_usecase.dart';
import '../../../../../domain/usecases/driver/wallet/reload_driver_wallet_usecase.dart';
import '../../../../../domain/usecases/driver/wallet/subscribe_driver_wallet_package_usecase.dart';
import '../../../../../domain/usecases/driver/wallet/withdraw_driver_wallet_usecase.dart';
import '../../../../../domain/usecases/usecase.dart';
import '../../../../../shared/models/auth_state.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../models/driver_wallet_operation_result.dart';
import 'driver_wallet_dependencies.dart';
import 'driver_wallet_state.dart';

class DriverWalletNotifier extends StateNotifier<DriverWalletState> {
  DriverWalletNotifier({
    required this.ref,
    required GetDriverWalletOverviewUseCase getOverviewUseCase,
    required GetDriverWalletPackagesUseCase getPackagesUseCase,
    required SubscribeDriverWalletPackageUseCase subscribePackageUseCase,
    required ReloadDriverWalletUseCase reloadWalletUseCase,
    required WithdrawDriverWalletUseCase withdrawWalletUseCase,
    required InitializeOrangeMoneyReloadUseCase initializeOrangeMoneyUseCase,
    required VerifyOrangeMoneyReloadUseCase verifyOrangeMoneyUseCase,
  }) : _getOverviewUseCase = getOverviewUseCase,
       _getPackagesUseCase = getPackagesUseCase,
       _subscribePackageUseCase = subscribePackageUseCase,
       _reloadWalletUseCase = reloadWalletUseCase,
       _withdrawWalletUseCase = withdrawWalletUseCase,
       _initializeOrangeMoneyUseCase = initializeOrangeMoneyUseCase,
       _verifyOrangeMoneyUseCase = verifyOrangeMoneyUseCase,
       super(const DriverWalletState()) {
    loadWallet();
  }

  final Ref ref;
  final GetDriverWalletOverviewUseCase _getOverviewUseCase;
  final GetDriverWalletPackagesUseCase _getPackagesUseCase;
  final SubscribeDriverWalletPackageUseCase _subscribePackageUseCase;
  final ReloadDriverWalletUseCase _reloadWalletUseCase;
  final WithdrawDriverWalletUseCase _withdrawWalletUseCase;
  final InitializeOrangeMoneyReloadUseCase _initializeOrangeMoneyUseCase;
  final VerifyOrangeMoneyReloadUseCase _verifyOrangeMoneyUseCase;

  Future<void> loadWallet() async {
    if (state.isLoading) {
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    final profileWallet = ref.read(driverProfileWalletInfoProvider);
    if (profileWallet.walletId != null && state.walletId == null) {
      state = state.copyWith(walletId: profileWallet.walletId);
    }
    final result = await _getOverviewUseCase(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        balance: profileWallet.solde ?? state.balance,
      ),
      (overview) {
        final walletId = overview.walletId ?? profileWallet.walletId;
        final balance = overview.walletId != null
            ? overview.balance
            : (profileWallet.solde ?? overview.balance);
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          balance: balance,
          walletId: walletId,
          transactions: overview.transactions,
        );
      },
    );
  }

  Future<void> loadPackages({bool forceRefresh = false}) async {
    if (!forceRefresh && state.packages.isNotEmpty) return;
    state = state.copyWith(isLoadingPackages: true);
    final result = await _getPackagesUseCase(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(
        isLoadingPackages: false,
        errorMessage: failure.message,
      ),
      (packages) =>
          state = state.copyWith(isLoadingPackages: false, packages: packages),
    );
  }

  Future<DriverWalletOperationResult> subscribeToPackage(
    DriverWalletPackage package,
  ) async {
    if (state.isSubmitting) {
      return DriverWalletOperationResult.ignored(
        DriverWalletOperationType.packageSubscription,
      );
    }
    final userId = ref.read(driverAuthProvider).userData?['id'] as int?;
    if (userId == null) {
      return DriverWalletOperationResult.failure(
        operationType: DriverWalletOperationType.packageSubscription,
        message: 'Utilisateur introuvable.',
      );
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _subscribePackageUseCase(
      SubscribeDriverWalletPackageParams(
        sidUserId: userId,
        packageId: package.id,
      ),
    );
    return await result.fold<Future<DriverWalletOperationResult>>(
      (failure) async {
        state = state.copyWith(isSubmitting: false);
        return DriverWalletOperationResult.failure(
          operationType: DriverWalletOperationType.packageSubscription,
          message: failure.message,
        );
      },
      (subscriptionResult) async {
        state = state.copyWith(isSubmitting: false);
        await loadWallet();
        return DriverWalletOperationResult.packageSuccess(subscriptionResult);
      },
    );
  }

  Future<DriverWalletOperationResult> reloadWallet({
    required double amount,
    required String? walletId,
  }) async {
    if (state.isSubmitting) {
      return DriverWalletOperationResult.ignored(
        DriverWalletOperationType.reload,
      );
    }
    if (amount <= 0) {
      return DriverWalletOperationResult.failure(
        operationType: DriverWalletOperationType.reload,
        message: 'Le montant doit être supérieur à 0.',
      );
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _reloadWalletUseCase(
      ReloadDriverWalletParams(
        amount: amount,
        walletId: _resolveWalletId(walletId),
      ),
    );
    return await result.fold<Future<DriverWalletOperationResult>>(
      (failure) async {
        state = state.copyWith(isSubmitting: false);
        return DriverWalletOperationResult.failure(
          operationType: DriverWalletOperationType.reload,
          message: failure.message,
        );
      },
      (reloadResult) async {
        state = state.copyWith(isSubmitting: false);
        await loadWallet();
        return DriverWalletOperationResult.reloadSuccess(reloadResult);
      },
    );
  }

  /// Étape 1 d'une recharge Orange Money : crée le paiement ; le résultat porte l'[OrangeMoneyPayment].
  Future<DriverWalletOperationResult> startOrangeMoneyReload({
    required double amount,
  }) async {
    if (state.isSubmitting) {
      return DriverWalletOperationResult.ignored(
        DriverWalletOperationType.reload,
      );
    }
    if (amount <= 0) {
      return DriverWalletOperationResult.failure(
        operationType: DriverWalletOperationType.reload,
        message: 'Le montant doit être supérieur à 0.',
      );
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _initializeOrangeMoneyUseCase(
      InitializeOrangeMoneyReloadParams(amount: amount),
    );
    state = state.copyWith(isSubmitting: false);
    return result.fold(
      (failure) => DriverWalletOperationResult.failure(
        operationType: DriverWalletOperationType.reload,
        message: failure.message,
      ),
      (payment) => DriverWalletOperationResult(
        operationType: DriverWalletOperationType.reload,
        isSuccess: true,
        isIgnored: false,
        message: '',
        payload: payment,
      ),
    );
  }

  Future<OrangeMoneyPaymentStatus> checkOrangeMoneyReload(
    String reference,
  ) async {
    final result = await _verifyOrangeMoneyUseCase(
      VerifyOrangeMoneyReloadParams(reference: reference),
    );
    return result.fold((_) => OrangeMoneyPaymentStatus.pending, (s) => s);
  }

  /// Dernière étape : tranche sur l'issue (une dernière vérification serveur si la fenêtre a été fermée
  /// ou n'a pas conclu), recharge le solde et produit le résultat affiché au chauffeur.
  Future<DriverWalletOperationResult> finishOrangeMoneyReload({
    required OrangeMoneyPayment payment,
    OrangeMoneyPaymentStatus? outcome,
  }) async {
    var status = outcome ?? OrangeMoneyPaymentStatus.pending;
    if (status == OrangeMoneyPaymentStatus.pending) {
      status = await checkOrangeMoneyReload(payment.reference);
    }
    switch (status) {
      case OrangeMoneyPaymentStatus.success:
        await loadWallet();
        return DriverWalletOperationResult.reloadSuccess(
          DriverWalletReloadResult(
            message: 'Rechargement Orange Money effectué avec succès.',
            reference: payment.reference,
          ),
        );
      case OrangeMoneyPaymentStatus.failed:
        return DriverWalletOperationResult.failure(
          operationType: DriverWalletOperationType.reload,
          message: "Le paiement Orange Money a échoué ou a été annulé.",
        );
      case OrangeMoneyPaymentStatus.pending:
        await loadWallet();
        return DriverWalletOperationResult.failure(
          operationType: DriverWalletOperationType.reload,
          message:
              "Paiement en attente de confirmation. Votre solde sera mis à jour dès qu'Orange Money l'aura confirmé.",
        );
    }
  }

  Future<bool> withdrawWallet({
    required double amount,
    required String? walletId,
  }) async {
    if (amount <= 0) {
      state = state.copyWith(
        errorMessage: 'Le montant doit être supérieur à 0.',
      );
      return false;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _withdrawWalletUseCase(
      WithdrawDriverWalletParams(
        amount: amount,
        walletId: _resolveWalletId(walletId),
      ),
    );
    return await result.fold(
      (failure) async {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) async {
        state = state.copyWith(isSubmitting: false);
        await loadWallet();
        return true;
      },
    );
  }

  void clearWallet() {
    state = const DriverWalletState();
  }

  String? _resolveWalletId(String? walletId) {
    return walletId ??
        state.walletId ??
        ref.read(driverProfileWalletInfoProvider).walletId;
  }
}

final driverWalletProvider =
    StateNotifierProvider<DriverWalletNotifier, DriverWalletState>((ref) {
      final notifier = DriverWalletNotifier(
        ref: ref,
        getOverviewUseCase: ref.watch(getDriverWalletOverviewUseCaseProvider),
        getPackagesUseCase: ref.watch(getDriverWalletPackagesUseCaseProvider),
        subscribePackageUseCase: ref.watch(
          subscribeDriverWalletPackageUseCaseProvider,
        ),
        reloadWalletUseCase: ref.watch(reloadDriverWalletUseCaseProvider),
        withdrawWalletUseCase: ref.watch(withdrawDriverWalletUseCaseProvider),
        initializeOrangeMoneyUseCase: ref.watch(
          initializeOrangeMoneyReloadUseCaseProvider,
        ),
        verifyOrangeMoneyUseCase: ref.watch(
          verifyOrangeMoneyReloadUseCaseProvider,
        ),
      );

      ref.listen<AuthState>(driverAuthProvider, (previous, next) {
        if (next.status == AuthStatus.unauthenticated) {
          notifier.clearWallet();
        } else if (next.status == AuthStatus.authenticated &&
            previous?.status != AuthStatus.authenticated) {
          notifier.loadWallet();
        }
      });

      return notifier;
    });
