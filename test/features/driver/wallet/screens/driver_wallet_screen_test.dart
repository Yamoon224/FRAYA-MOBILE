import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_overview.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_package.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_package_subscription_result.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_reload_result.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_transaction.dart';
import 'package:fraya_mobile/domain/repositories/driver_wallet_repository.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/driver_wallet_dependencies.dart';
import 'package:fraya_mobile/features/driver/wallet/screens/driver_wallet_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/driver_test_doubles.dart';

class ScreenFakeWalletRepository implements DriverWalletRepository {
  int fetchWalletOverviewCalls = 0;
  int fetchPackagesCalls = 0;
  int subscribeCalls = 0;
  int reloadCalls = 0;
  Completer<void>? reloadCompleter;
  Completer<void>? subscribeCompleter;
  Object? reloadError;
  Object? subscribeError;
  DriverWalletReloadResult reloadResult = const DriverWalletReloadResult(
    message: 'Recharge initiée par l’API.',
  );
  DriverWalletPackageSubscriptionResult subscriptionResult =
      const DriverWalletPackageSubscriptionResult(
        message: 'Souscription confirmée par l’API.',
        newBalance: 11000,
        amountDebited: 1500,
        transactionReference: 'SUB-001',
      );
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
    fetchWalletOverviewCalls++;
    return DriverWalletOverview(
      balance: 12500,
      walletId: 'Fra-I4JUY',
      transactions: [
        DriverWalletTransaction(
          id: 'tx-1',
          title: 'Recharge',
          subtitle: 'Wave',
          amount: 5000,
          isCredit: true,
          occurredAt: DateTime(2026, 2, 25, 8, 30),
          type: DriverWalletTransactionType.recharge,
        ),
      ],
    );
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
  }) async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
  });

  testWidgets('renders wallet summary and opens direct package sheet', (
    tester,
  ) async {
    final repository = ScreenFakeWalletRepository();

    await _pumpWalletScreen(tester, repository);

    expect(find.text('Mon Portefeuille'), findsOneWidget);
    expect(find.text('Historique des transactions'), findsOneWidget);
    expect(find.text('Recharge'), findsOneWidget);
    expect(find.text('Information importante'), findsOneWidget);
    expect(
      find.textContaining('commissions Fraya de vos courses'),
      findsOneWidget,
    );

    await tester.tap(find.text('Souscription'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir un package'), findsNothing);
    expect(find.text('Souscription au package'), findsOneWidget);
    expect(find.text('Pack Journalier - Starter VTC'), findsOneWidget);
    expect(find.text('Confirmer la souscription'), findsOneWidget);
    expect(repository.fetchPackagesCalls, 1);
  });

  testWidgets('shows reload progress then exact API success message', (
    tester,
  ) async {
    final repository = ScreenFakeWalletRepository()
      ..reloadCompleter = Completer<void>()
      ..reloadResult = const DriverWalletReloadResult(
        message: 'Recharge acceptée par l’API.',
      );

    await _pumpWalletScreen(tester, repository);

    await tester.tap(find.text('Recharger'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2500');
    await tester.ensureVisible(find.text('Confirmer le paiement'));
    await tester.tap(find.text('Confirmer le paiement'));
    await tester.pump();

    expect(find.text('Traitement en cours'), findsOneWidget);

    repository.reloadCompleter!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Recharge acceptée par l’API.'), findsOneWidget);
  });

  testWidgets('shows reload failure with retry and edit actions', (
    tester,
  ) async {
    final repository = ScreenFakeWalletRepository()
      ..reloadError = ServerException(message: 'Échec renvoyé par l’API.');

    await _pumpWalletScreen(tester, repository);

    await tester.tap(find.text('Recharger'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2500');
    await tester.ensureVisible(find.text('Confirmer le paiement'));
    await tester.tap(find.text('Confirmer le paiement'));
    await tester.pumpAndSettle();

    expect(find.text('Échec renvoyé par l’API.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);

    await tester.tap(find.text('Modifier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Recharger le compte'), findsOneWidget);
    expect(find.text('2500'), findsOneWidget);
  });

  testWidgets('shows package progress then exact API success message', (
    tester,
  ) async {
    final repository = ScreenFakeWalletRepository()
      ..subscribeCompleter = Completer<void>()
      ..subscriptionResult = const DriverWalletPackageSubscriptionResult(
        message: 'Souscription validée par l’API.',
      );

    await _pumpWalletScreen(tester, repository);

    await tester.tap(find.text('Souscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer la souscription'));
    await tester.pump();

    expect(find.text('Traitement en cours'), findsOneWidget);

    repository.subscribeCompleter!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Souscription validée par l’API.'), findsOneWidget);
  });

  testWidgets('reopens direct package sheet on package failure edit', (
    tester,
  ) async {
    final repository = ScreenFakeWalletRepository()
      ..subscribeError = ServerException(message: 'Echec souscription API.');

    await _pumpWalletScreen(tester, repository);

    await tester.tap(find.text('Souscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer la souscription'));
    await tester.pumpAndSettle();

    expect(find.text('Echec souscription API.'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(find.text('Souscription au package'), findsOneWidget);
    expect(find.text('Pack Journalier - Starter VTC'), findsOneWidget);
    expect(find.text('Confirmer la souscription'), findsOneWidget);
  });

  testWidgets('shows multi-package fallback without old wording', (
    tester,
  ) async {
    final repository = ScreenFakeWalletRepository()
      ..packages = const [
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
        DriverWalletPackage(
          id: 9,
          name: 'Pack Journalier - Pro VTC',
          description: 'Pour les chauffeurs reguliers.',
          trialDays: 0,
          dailyPrice: 2500,
          maxRides: 20,
          maxCancellations: 3,
          status: true,
          isRecommended: true,
          isPrivate: false,
          type: 'standard',
          isMonthly: false,
          isAnnual: false,
        ),
      ];

    await _pumpWalletScreen(tester, repository);

    await tester.tap(find.text('Souscription'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir un package'), findsNothing);
    expect(find.text('Souscription au package'), findsOneWidget);
    expect(find.text('Pack Journalier - Starter VTC'), findsOneWidget);
    expect(find.text('Pack Journalier - Pro VTC'), findsOneWidget);
    expect(find.text('Confirmer la souscription'), findsNothing);

    await tester.tap(find.text('Pack Journalier - Pro VTC'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la souscription'), findsOneWidget);
  });

  testWidgets('keeps empty package state functional', (tester) async {
    final repository = ScreenFakeWalletRepository()..packages = const [];

    await _pumpWalletScreen(tester, repository);

    await tester.tap(find.text('Souscription'));
    await tester.pumpAndSettle();

    expect(find.text('Souscription au package'), findsOneWidget);
    expect(find.text('Aucun package disponible.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Recharger'), findsOneWidget);
  });

  testWidgets('dismisses the wallet commission notice', (tester) async {
    final repository = ScreenFakeWalletRepository();

    await _pumpWalletScreen(tester, repository);

    expect(find.text('Information importante'), findsOneWidget);

    await tester.tap(find.byTooltip('Masquer cette information'));
    await tester.pumpAndSettle();

    expect(find.text('Information importante'), findsNothing);
    expect(
      LocalStorage.instance.getBool(
        AppConstants.driverWalletCommissionNoticeDismissedKey,
      ),
      isTrue,
    );
  });

  testWidgets('keeps the wallet commission notice hidden when dismissed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.driverWalletCommissionNoticeDismissedKey: true,
    });
    await LocalStorage.instance.init();
    final repository = ScreenFakeWalletRepository();

    await _pumpWalletScreen(tester, repository);

    expect(find.text('Information importante'), findsNothing);
  });

  testWidgets('pull refresh reloads wallet overview', (tester) async {
    final repository = ScreenFakeWalletRepository();

    await _pumpWalletScreen(tester, repository);

    expect(repository.fetchWalletOverviewCalls, 1);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 360));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.fetchWalletOverviewCalls, 2);
  });
}

Future<void> _pumpWalletScreen(
  WidgetTester tester,
  ScreenFakeWalletRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        driverAuthProvider.overrideWith((ref) => _fakeAuthNotifier()),
        driverWalletRepositoryProvider.overrideWithValue(repository),
        driverWalletCompletedRidesProvider.overrideWithValue(const []),
      ],
      child: const MaterialApp(home: DriverWalletScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

FakeDriverAuthNotifier _fakeAuthNotifier() {
  return FakeDriverAuthNotifier(
    AuthState(
      status: AuthStatus.authenticated,
      userData: const {'userId': 19, 'driverId': 19, 'id': 19},
    ),
  );
}
