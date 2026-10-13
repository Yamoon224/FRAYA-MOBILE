import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_overview.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_package.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_package_subscription_result.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_reload_result.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_transaction.dart';
import 'package:fraya_mobile/domain/models/orange_money_payment.dart';
import 'package:fraya_mobile/domain/repositories/driver_wallet_repository.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/driver_wallet_dependencies.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/driver_wallet_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

import '../../../../support/driver_test_doubles.dart';

class FakeDriverWalletRepository implements DriverWalletRepository {
  DriverWalletOverview overview = DriverWalletOverview(
    balance: 12000,
    walletId: 'Fra-I4JUY',
    transactions: [
      DriverWalletTransaction(
        id: 'reload-1',
        title: 'Recharge',
        subtitle: 'Wave',
        amount: 5000,
        isCredit: true,
        occurredAt: DateTime(2026, 2, 25, 8, 30),
        type: DriverWalletTransactionType.recharge,
      ),
    ],
  );
  DriverWalletReloadResult reloadResult = const DriverWalletReloadResult(
    message: 'Rechargement initié avec succès.',
  );
  DriverWalletPackageSubscriptionResult subscriptionResult =
      const DriverWalletPackageSubscriptionResult(
        message: 'Souscription effectuee avec succes.',
        previousBalance: 3100,
        newBalance: 1600,
        amountDebited: 1500,
        transactionReference: 'SUB_1780706507933_etwyj8y7',
        packageName: 'Pack Journalier - Starter VTC',
      );
  int fetchCalls = 0;
  int reloadCalls = 0;
  int withdrawCalls = 0;
  int fetchPackagesCalls = 0;
  int subscribeCalls = 0;
  double? lastAmount;
  String? lastWalletId;
  int? lastSidUserId;
  int? lastPackageId;
  Object? subscribeError;
  Object? reloadError;
  Completer<void>? reloadCompleter;
  Completer<void>? subscribeCompleter;
  List<DriverWalletPackage> packages = const [
    DriverWalletPackage(
      id: 8,
      name: 'Pack Journalier - Starter VTC',
      description: 'Ideal pour les chauffeurs a temps partiel.',
      trialDays: 0,
      dailyPrice: 1500,
      maxRides: 12,
      maxCancellations: 2,
      status: true,
      isRecommended: false,
      isPrivate: false,
      type: 'standard',
      isMonthly: false,
      isAnnual: false,
    ),
  ];

  @override
  Future<DriverWalletOverview> fetchWalletOverview() async {
    fetchCalls++;
    return overview;
  }

  @override
  Future<List<DriverWalletPackage>> fetchPackages() async {
    fetchPackagesCalls++;
    return packages;
  }

  @override
  Future<DriverWalletPackageSubscriptionResult> subscribeToPackage({
    required int sidUserId,
    required int packageId,
  }) async {
    subscribeCalls++;
    lastSidUserId = sidUserId;
    lastPackageId = packageId;
    if (subscribeCompleter != null) {
      await subscribeCompleter!.future;
    }
    if (subscribeError != null) throw subscribeError!;
    return subscriptionResult;
  }

  @override
  Future<DriverWalletReloadResult> reloadWallet({
    required double amount,
    String? walletId,
  }) async {
    reloadCalls++;
    lastAmount = amount;
    lastWalletId = walletId;
    if (reloadCompleter != null) {
      await reloadCompleter!.future;
    }
    if (reloadError != null) throw reloadError!;
    return reloadResult;
  }

  @override
  Future<void> withdrawWallet({
    required double amount,
    String? walletId,
  }) async {
    withdrawCalls++;
    lastAmount = amount;
    lastWalletId = walletId;
  }

  OrangeMoneyPayment orangeMoneyPayment = const OrangeMoneyPayment(
    paymentUrl: 'https://webpayment.orange.test/pay/abc',
    reference: 'FRAYA_OM_1_ABCD',
  );
  Object? orangeMoneyInitError;
  OrangeMoneyPaymentStatus orangeMoneyStatus = OrangeMoneyPaymentStatus.pending;
  Object? orangeMoneyVerifyError;
  int orangeMoneyInitCalls = 0;
  int orangeMoneyVerifyCalls = 0;
  double? lastOrangeMoneyAmount;

  @override
  Future<OrangeMoneyPayment> initializeOrangeMoneyReload({
    required double amount,
  }) async {
    orangeMoneyInitCalls++;
    lastOrangeMoneyAmount = amount;
    if (orangeMoneyInitError != null) throw orangeMoneyInitError!;
    return orangeMoneyPayment;
  }

  @override
  Future<OrangeMoneyPaymentStatus> verifyOrangeMoneyReload(
    String reference,
  ) async {
    orangeMoneyVerifyCalls++;
    if (orangeMoneyVerifyError != null) throw orangeMoneyVerifyError!;
    return orangeMoneyStatus;
  }
}

void main() {
  test('loads wallet overview transactions from repository', () async {
    final walletRepo = FakeDriverWalletRepository();
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
        driverWalletRepositoryProvider.overrideWithValue(walletRepo),
        driverWalletCompletedRidesProvider.overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);

    await _waitUntilLoaded(container);
    final state = container.read(driverWalletProvider);

    expect(state.balance, 12000);
    expect(state.transactions.length, 1);
    expect(state.transactions.single.title, 'Recharge');
  });

  test('rejects invalid amount before calling reload endpoint', () async {
    final walletRepo = FakeDriverWalletRepository();
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
        driverWalletRepositoryProvider.overrideWithValue(walletRepo),
        driverWalletCompletedRidesProvider.overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    final result = await container
        .read(driverWalletProvider.notifier)
        .reloadWallet(amount: 0, walletId: null);

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('supérieur'));
    expect(walletRepo.reloadCalls, 0);
  });

  test('reload returns structured result with API message', () async {
    final walletRepo = FakeDriverWalletRepository();
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
        driverWalletRepositoryProvider.overrideWithValue(walletRepo),
        driverWalletCompletedRidesProvider.overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    final result = await container
        .read(driverWalletProvider.notifier)
        .reloadWallet(amount: 2500, walletId: 'Fra-I4JUY');

    expect(result.isSuccess, isTrue);
    expect(result.message, 'Rechargement initié avec succès.');
    expect(walletRepo.lastAmount, 2500);
    expect(walletRepo.lastWalletId, 'Fra-I4JUY');
  });

  test('ignores concurrent reload submissions', () async {
    final walletRepo = FakeDriverWalletRepository()
      ..reloadCompleter = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
        driverWalletRepositoryProvider.overrideWithValue(walletRepo),
        driverWalletCompletedRidesProvider.overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    final first = container
        .read(driverWalletProvider.notifier)
        .reloadWallet(amount: 2500, walletId: 'Fra-I4JUY');
    final second = await container
        .read(driverWalletProvider.notifier)
        .reloadWallet(amount: 2500, walletId: 'Fra-I4JUY');

    expect(second.isIgnored, isTrue);
    expect(walletRepo.reloadCalls, 1);

    walletRepo.reloadCompleter!.complete();
    await first;
  });

  test('loads visible packages from repository', () async {
    final walletRepo = FakeDriverWalletRepository();
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
        driverWalletRepositoryProvider.overrideWithValue(walletRepo),
        driverWalletCompletedRidesProvider.overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    await container.read(driverWalletProvider.notifier).loadPackages();

    expect(walletRepo.fetchPackagesCalls, 1);
    expect(container.read(driverWalletProvider).packages.single.id, 8);
  });

  test('subscribes to selected package with structured result', () async {
    final walletRepo = FakeDriverWalletRepository();
    final authNotifier = FakeDriverAuthNotifier(
      AuthState(
        status: AuthStatus.authenticated,
        userData: const {'userId': 19, 'driverId': 19, 'id': 19},
      ),
    );
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => authNotifier),
        driverWalletRepositoryProvider.overrideWithValue(walletRepo),
        driverWalletCompletedRidesProvider.overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    walletRepo.overview = const DriverWalletOverview(
      balance: 1600,
      walletId: 'Fra-I4JUY',
      transactions: [],
    );

    final result = await container
        .read(driverWalletProvider.notifier)
        .subscribeToPackage(walletRepo.packages.single);
    await _waitUntilLoaded(container);

    expect(result.isSuccess, isTrue);
    expect(result.message, 'Souscription effectuee avec succes.');
    expect(walletRepo.lastSidUserId, 19);
    expect(walletRepo.lastPackageId, 8);
    expect(container.read(driverWalletProvider).balance, 1600);
  });

  test('ignores concurrent package submissions', () async {
    final walletRepo = FakeDriverWalletRepository()
      ..subscribeCompleter = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
        driverWalletRepositoryProvider.overrideWithValue(walletRepo),
        driverWalletCompletedRidesProvider.overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(container);

    final first = container
        .read(driverWalletProvider.notifier)
        .subscribeToPackage(walletRepo.packages.single);
    final second = await container
        .read(driverWalletProvider.notifier)
        .subscribeToPackage(walletRepo.packages.single);

    expect(second.isIgnored, isTrue);
    expect(walletRepo.subscribeCalls, 1);

    walletRepo.subscribeCompleter!.complete();
    await first;
  });

  test(
    'clearWallet resets balance and transactions to initial state',
    () async {
      final walletRepo = FakeDriverWalletRepository();
      final container = ProviderContainer(
        overrides: [
          driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
          driverWalletRepositoryProvider.overrideWithValue(walletRepo),
          driverWalletCompletedRidesProvider.overrideWithValue(const []),
        ],
      );
      addTearDown(container.dispose);

      await _waitUntilLoaded(container);
      expect(container.read(driverWalletProvider).transactions, isNotEmpty);

      container.read(driverWalletProvider.notifier).clearWallet();

      final cleared = container.read(driverWalletProvider);
      expect(cleared.transactions, isEmpty);
      expect(cleared.balance, 0);
      expect(cleared.isLoading, isFalse);
    },
  );

  group('Orange Money reload', () {
    Future<(ProviderContainer, FakeDriverWalletRepository)> setUp() async {
      final walletRepo = FakeDriverWalletRepository();
      final container = ProviderContainer(
        overrides: [
          driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
          driverWalletRepositoryProvider.overrideWithValue(walletRepo),
          driverWalletCompletedRidesProvider.overrideWithValue(const []),
        ],
      );
      addTearDown(container.dispose);
      await _waitUntilLoaded(container);
      return (container, walletRepo);
    }

    test(
      'start returns the payment to open and does not touch the legacy reload',
      () async {
        final (container, repo) = await setUp();

        final result = await container
            .read(driverWalletProvider.notifier)
            .startOrangeMoneyReload(amount: 2500);

        expect(result.isSuccess, isTrue);
        expect(result.payload, isA<OrangeMoneyPayment>());
        expect(
          (result.payload as OrangeMoneyPayment).reference,
          'FRAYA_OM_1_ABCD',
        );
        expect(repo.lastOrangeMoneyAmount, 2500);
        expect(repo.reloadCalls, 0, reason: 'plus de faux succès de recharge');
        expect(container.read(driverWalletProvider).isSubmitting, isFalse);
      },
    );

    test(
      'start rejects a non-positive amount without calling the server',
      () async {
        final (container, repo) = await setUp();

        final result = await container
            .read(driverWalletProvider.notifier)
            .startOrangeMoneyReload(amount: 0);

        expect(result.isSuccess, isFalse);
        expect(repo.orangeMoneyInitCalls, 0);
      },
    );

    test(
      'start surfaces the server error and releases the submit lock',
      () async {
        final (container, repo) = await setUp();
        repo.orangeMoneyInitError = const ServerException(
          message: 'Les clés Orange Money ne sont pas configurées',
        );

        final result = await container
            .read(driverWalletProvider.notifier)
            .startOrangeMoneyReload(amount: 1000);

        expect(result.isSuccess, isFalse);
        expect(result.message, contains('clés Orange Money'));
        expect(container.read(driverWalletProvider).isSubmitting, isFalse);
      },
    );

    test(
      'check treats a network error as still pending, never as success',
      () async {
        final (container, repo) = await setUp();
        repo.orangeMoneyVerifyError = const NetworkException();

        final status = await container
            .read(driverWalletProvider.notifier)
            .checkOrangeMoneyReload('FRAYA_OM_1_ABCD');

        expect(status, OrangeMoneyPaymentStatus.pending);
      },
    );

    test(
      'finish after a confirmed payment reloads the balance and reports success',
      () async {
        final (container, repo) = await setUp();
        final notifier = container.read(driverWalletProvider.notifier);
        final fetchesBefore = repo.fetchCalls;
        repo.overview = const DriverWalletOverview(
          balance: 14500,
          walletId: 'Fra-I4JUY',
          transactions: [],
        );

        final result = await notifier.finishOrangeMoneyReload(
          payment: repo.orangeMoneyPayment,
          outcome: OrangeMoneyPaymentStatus.success,
        );

        expect(result.isSuccess, isTrue);
        expect(result.message, contains('Orange Money'));
        expect(repo.fetchCalls, greaterThan(fetchesBefore));
        expect(container.read(driverWalletProvider).balance, 14500);
        expect(repo.orangeMoneyVerifyCalls, 0, reason: 'issue déjà connue');
      },
    );

    test(
      'finish after a refused payment reports a failure without crediting',
      () async {
        final (container, repo) = await setUp();

        final result = await container
            .read(driverWalletProvider.notifier)
            .finishOrangeMoneyReload(
              payment: repo.orangeMoneyPayment,
              outcome: OrangeMoneyPaymentStatus.failed,
            );

        expect(result.isSuccess, isFalse);
        expect(result.message, contains('échoué'));
        expect(container.read(driverWalletProvider).balance, 12000);
      },
    );

    test(
      'closing the window triggers one last server check (paid just before closing)',
      () async {
        final (container, repo) = await setUp();
        repo.orangeMoneyStatus = OrangeMoneyPaymentStatus.success;

        final result = await container
            .read(driverWalletProvider.notifier)
            .finishOrangeMoneyReload(
              payment: repo.orangeMoneyPayment,
              outcome: null,
            );

        expect(repo.orangeMoneyVerifyCalls, 1);
        expect(result.isSuccess, isTrue);
      },
    );

    test(
      'closing the window with the payment unconfirmed explains it is pending',
      () async {
        final (container, repo) = await setUp();
        repo.orangeMoneyStatus = OrangeMoneyPaymentStatus.pending;

        final result = await container
            .read(driverWalletProvider.notifier)
            .finishOrangeMoneyReload(
              payment: repo.orangeMoneyPayment,
              outcome: null,
            );

        expect(result.isSuccess, isFalse);
        expect(result.message, contains('en attente'));
      },
    );
  });
}

Future<void> _waitUntilLoaded(ProviderContainer container) async {
  for (var i = 0; i < 40; i++) {
    if (!container.read(driverWalletProvider).isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

FakeDriverAuthNotifier _fakeAuthNotifier() {
  return FakeDriverAuthNotifier(
    AuthState(
      status: AuthStatus.authenticated,
      userData: const {'userId': 19, 'driverId': 19, 'id': 19},
    ),
  );
}
