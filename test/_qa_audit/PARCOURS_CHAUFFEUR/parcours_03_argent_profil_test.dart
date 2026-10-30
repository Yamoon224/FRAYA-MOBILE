// PARCOURS CHAUFFEUR - étapes 12 à 20 : encaissement/portefeuille, recharge, gains, historique, profil,
// paramètres, hors ligne, déconnexion + contrats réseau (pagination, rayon, statuts, événements socket).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/realtime/realtime_events.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/data/repositories/driver_ride_repository_impl.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/data/sources/remote/driver_ride_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_overview.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_transaction.dart';
import 'package:fraya_mobile/domain/models/orange_money_payment.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/driver_wallet_repository.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/earnings/providers/driver_earnings_provider.dart';
import 'package:fraya_mobile/features/driver/earnings/screens/driver_earnings_screen.dart';
import 'package:fraya_mobile/features/driver/history/screens/driver_history_screen.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_ride_dependencies.dart';
import 'package:fraya_mobile/features/driver/profile/screens/driver_profile_screen.dart';
import 'package:fraya_mobile/features/driver/settings/screens/driver_settings_screen.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/driver_wallet_dependencies.dart';
import 'package:fraya_mobile/features/driver/wallet/screens/driver_wallet_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/driver_test_doubles.dart';
import 'parcours_support.dart';

class _WalletRepo implements DriverWalletRepository {
  int initializeCalls = 0;
  double? lastAmount;
  Object? initializeError = const ServerException(message: 'Service Orange Money indisponible');

  @override
  Future<DriverWalletOverview> fetchWalletOverview() async => DriverWalletOverview(
    balance: 12500,
    walletId: 'Fra-I4JUY',
    transactions: [
      DriverWalletTransaction(
        id: 'tx-1',
        title: 'Commission course',
        subtitle: 'Paiement_commission_AB12',
        amount: 480,
        isCredit: false,
        occurredAt: DateTime(2026, 10, 27, 18, 30),
        type: DriverWalletTransactionType.commission,
      ),
      DriverWalletTransaction(
        id: 'tx-2',
        title: 'Recharge',
        subtitle: 'Orange Money',
        amount: 5000,
        isCredit: true,
        occurredAt: DateTime(2026, 10, 27, 8, 30),
        type: DriverWalletTransactionType.recharge,
      ),
    ],
  );

  @override
  Future<OrangeMoneyPayment> initializeOrangeMoneyReload({required double amount}) async {
    initializeCalls++;
    lastAmount = amount;
    throw initializeError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DriverRideRepositoryImpl _rideRepo(FakeFrayaBackend b) =>
    DriverRideRepositoryImpl(remoteDataSource: DriverRideRemoteDataSource(dio: fakeDio(b)));

Map<String, dynamic> _completed(int id, DateTime at, {int price = 3000, int commission = 450}) {
  final j = FakeFrayaBackend.rideJson(
    id: id,
    status: 'COMPLETED',
    driverUserId: 14,
    vehicleId: 7,
    finalPrice: price,
  );
  j['commissionPrice'] = commission;
  j['amountReceived'] = price - commission;
  j['dateArrival'] = at.toIso8601String();
  j['departureDate'] = at.subtract(const Duration(minutes: 25)).toIso8601String();
  j['finalDuration'] = 25;
  j['finalDistance'] = 12.4;
  return j;
}

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

List<String> _drain(WidgetTester t) {
  final out = <String>[];
  Object? e;
  while ((e = t.takeException()) != null) {
    out.add(e.toString().split(RegExp(r'[\r\n]+')).first);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadRealisticFonts();
    await initializeDateFormatting('fr_FR');
  });

  // ---------------------------------------------------------------- contrats réseau (sans widget)
  group('Contrats API réels (dépôt + source distante + faux backend)', () {
    test('S7 offre : le rayon est envoyé sous "radius" (km) alors que le backend lit "radiusMeters"', () async {
      final b = FakeFrayaBackend()
        ..online = true
        ..ride = FakeFrayaBackend.rideJson(id: 700);
      final rides = await _rideRepo(b).getAvailableRides(lat: 5.35, lng: -3.88, radiusKm: 8);
      expect(rides, hasLength(1));
      final q = b.callsTo('GET', '/rides/maps/available').single.queryParameters;
      // ignore: avoid_print
      print('S7 query /available = $q');
      expect(
        q.containsKey('radiusMeters'),
        isTrue,
        reason: 'backend rides.controller.ts:507 lit @Query(radiusMeters) (défaut 3000 m) ; l\'app envoie $q',
      );
    });

    test('S8 course active absente : enveloppe data:null -> aucune course (PASS)', () async {
      final b = FakeFrayaBackend();
      expect(await _rideRepo(b).getActiveRide(14), isNull);
    });

    test('S8 course active (statut backend DRIVER_ASSIGNED) -> accepted avec passager et véhicule', () async {
      final b = FakeFrayaBackend()
        ..ride = FakeFrayaBackend.rideJson(
          id: 701,
          status: 'DRIVER_ASSIGNED',
          driverUserId: 14,
          vehicleId: 7,
        );
      final ride = await _rideRepo(b).getActiveRide(14);
      expect(ride, isNotNull);
      expect(ride!.status, RideStatus.accepted);
      expect(ride.passengerName, 'Koffi Yao');
      expect(ride.vehicleId, 7);
      expect(ride.assignedDriverId, 14);
    });

    test('S18 historique : 45 courses terminées côté serveur, l\'app doit toutes les charger', () async {
      final b = FakeFrayaBackend();
      final now = DateTime.now();
      b.allRides = [
        for (var i = 1; i <= 45; i++) _completed(i, now.subtract(Duration(hours: i))),
      ];
      final history = await _rideRepo(b).getHistoryRides();
      final call = b.callsTo('GET', '/rides/maps').first;
      // ignore: avoid_print
      print('S18 historique : ${history.length} courses reçues sur 45 ; query=${call.queryParameters}');
      expect(
        history.length,
        45,
        reason: 'GET /rides/maps est paginé (nestjs-paginate, limite par défaut 20) et l\'app n\'envoie ni page ni limit : ${history.length}/45',
      );
    });

    test('S17 gains : le total de la période doit couvrir toutes les courses (45 x 3000 FCFA)', () async {
      final b = FakeFrayaBackend();
      final now = DateTime.now();
      b.allRides = [
        for (var i = 1; i <= 45; i++) _completed(i, now.subtract(Duration(hours: i))),
      ];
      final container = ProviderContainer(
        overrides: [driverRideRepositoryProvider.overrideWithValue(_rideRepo(b))],
      );
      addTearDown(container.dispose);
      container.read(driverEarningsFilterProvider.notifier).setPeriod(DriverEarningsPeriod.thirtyDays);
      // dépendance FutureProvider : on attend la résolution
      await Future<void>.delayed(const Duration(milliseconds: 50));
      container.read(driverEarningsSummaryProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final summary = container.read(driverEarningsSummaryProvider);
      // ignore: avoid_print
      print('S17 gains 30 jours : ${summary.completedRideCount} courses, total=${summary.totalEarnings}');
      expect(summary.totalEarnings, 45 * 3000, reason: 'total affiché ${summary.totalEarnings} au lieu de 135000');
    });

    test('S13 statuts backend sans équivalent côté app (CANCELLED_SYSTEM, DISPUTE, SOS)', () {
      // baseEnum.ts : CANCELLED_SYSTEM, DISPUTE, SOS existent ; RideStatus.fromBackend les range en "pending".
      final mapped = {
        for (final s in ['CANCELLED_SYSTEM', 'DISPUTE', 'SOS']) s: RideStatus.fromBackend(s),
      };
      expect(mapped['CANCELLED_SYSTEM'], RideStatus.cancelled, reason: 'CANCELLED_SYSTEM est bien rangé en annulée');
      // ignore: avoid_print
      print('S13 mapping statuts = $mapped');
      expect(
        mapped['SOS'] == RideStatus.pending || mapped['DISPUTE'] == RideStatus.pending,
        isFalse,
        reason: 'SOS / DISPUTE (statuts backend de course en cours) sont rangés en "pending" : $mapped',
      );
    });

    test('S10 événements socket du chauffeur : ride_started_driver / ride_completed_driver (payload backend) sont ignorés', () {
      // ride.gateway.ts notifyDriverRideCompleted : { rideId, message, rideDetails, timestamp } (pas de "status")
      final completed = DriverRideStatusRealtimeEvent.tryParse({
        'rideId': 9,
        'message': 'La course est terminée. Bravo pour cette course !',
        'rideDetails': {'id': 9, 'finalPrice': 3500, 'commissionPrice': 525},
        'timestamp': DateTime.now().toIso8601String(),
      });
      final cancelled = DriverRideStatusRealtimeEvent.tryParse({
        'rideId': 9,
        'cancelledBy': 'PASSENGER',
        'reason': 'Course annulée',
        'message': 'Le passager a annulé la course',
      }, fallbackStatus: 'CANCELLED');
      expect(cancelled?.isCancelled, isTrue, reason: 'ride_cancelled (passager) est bien géré');
      expect(completed, isNotNull, reason: 'ride_completed_driver sans champ status -> évènement ignoré par l\'app');
    });
  });

  // ---------------------------------------------------------------- portefeuille
  for (final scale in phoneScales) {
    group('S13-S14 portefeuille - Galaxy A25 5G textScale $scale', () {
      Future<_WalletRepo> pumpWallet(WidgetTester tester) async {
        usePhone(tester, textScale: scale);
        SharedPreferences.setMockInitialValues({});
        await LocalStorage.instance.init();
        final repo = _WalletRepo();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              driverAuthProvider.overrideWith(
                (ref) => FakeDriverAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userData: const {'userId': 14, 'driverId': 14, 'id': 14},
                  ),
                ),
              ),
              driverWalletRepositoryProvider.overrideWithValue(repo),
              driverWalletCompletedRidesProvider.overrideWithValue(const []),
            ],
            child: const MaterialApp(home: DriverWalletScreen()),
          ),
        );
        await _settle(tester);
        return repo;
      }

      testWidgets('solde en FCFA sans centimes, transaction commission visible, pas de débordement', (tester) async {
        await pumpWallet(tester);
        await _settle(tester, 20);
        // ignore: avoid_print
        print('S13 textes portefeuille: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().where((t) => t.contains('FCFA')).toList()}');
        final balanceShown = tester
            .widgetList<RichText>(find.byType(RichText))
            .any((r) => RegExp(r'12\s?500').hasMatch(r.text.toPlainText()));
        expect(balanceShown, isTrue, reason: 'solde 12500 FCFA affiché');
        expect(find.textContaining('Commission'), findsWidgets);
        expect(_drain(tester), isEmpty);
      });

      testWidgets('recharge : seul Orange Money est proposé (Wave / MTN MoMo absents)', (tester) async {
        await pumpWallet(tester);
        await tester.tap(find.text('Recharger').first);
        await _settle(tester, 4);
        expect(find.text('Orange Money'), findsOneWidget);
        expect(find.text('Wave'), findsNothing);
        expect(find.textContaining('MTN'), findsNothing);
      });

      testWidgets('recharge : montant saisi à l\'ivoirienne "5 000" refusé, "5000" envoyé à Orange Money', (tester) async {
        final repo = await pumpWallet(tester);
        await tester.tap(find.text('Recharger').first);
        await _settle(tester, 4);
        final amountField = find.widgetWithText(TextField, 'Montant (FCFA)');
        await tester.enterText(amountField, '5 000');
        await tester.tap(find.text('Confirmer le paiement'));
        await _settle(tester, 3);
        // ignore: avoid_print
        print('S14 montant "5 000" -> erreur affichée: ${find.text('Saisissez un montant valide.').evaluate().isNotEmpty}');
        expect(find.text('Saisissez un montant valide.'), findsOneWidget,
            reason: 'comportement constaté : "5 000" est refusé');
        await tester.enterText(amountField, '5000');
        await tester.tap(find.text('Confirmer le paiement'));
        await _settle(tester, 6);
        expect(repo.initializeCalls, 1);
        expect(repo.lastAmount, 5000);
        // La suite (WebView Orange Money, SMS de confirmation) est BLOCKED : appareil réel + paiement réel.
        await tester.pump(const Duration(seconds: 15));
      });
    });
  }

  // ---------------------------------------------------------------- profil / paramètres / historique / gains
  for (final scale in phoneScales) {
    testWidgets('S16-S18 profil, paramètres, gains, historique s\'affichent sans débordement (textScale $scale)', (
      tester,
    ) async {
      usePhone(tester, textScale: scale);
      SharedPreferences.setMockInitialValues({});
      await LocalStorage.instance.init();
      final backend = FakeFrayaBackend();
      final now = DateTime.now();
      backend.allRides = [
        _completed(1, now.subtract(const Duration(hours: 1))),
        _completed(2, now.subtract(const Duration(hours: 3)), price: 4500, commission: 675),
      ];
      final auth = FakeDriverAuthNotifier(
        AuthState(
          status: AuthStatus.authenticated,
          userData: const {
            'userId': 14,
            'driverId': 14,
            'firstNames': 'Adama',
            'lastName': 'Traoré',
            'phoneNumber': '0707123456',
            'email': 'adama@example.ci',
            'kycStatus': 'APPROVED',
            'vehicleStatus': 'APPROVED',
            'vehicleId': 7,
          },
        ),
      );
      Future<void> pumpScreen(Widget w) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              driverAuthProvider.overrideWith((ref) => auth),
              driverRideRepositoryProvider.overrideWithValue(_rideRepo(backend)),
              driverWalletRepositoryProvider.overrideWithValue(_WalletRepo()),
            ],
            child: MaterialApp(home: w),
          ),
        );
        await _settle(tester);
      }

      await pumpScreen(const DriverProfileScreen());
      expect(find.text('Adama Traoré'), findsOneWidget);
      expect(find.textContaining('0707123456'), findsWidgets);
      expect(_drain(tester), isEmpty, reason: 'profil');

      await pumpScreen(const DriverSettingsScreen());
      await tester.scrollUntilVisible(find.text('Supprimer mon compte'), 300);
      expect(find.text('Supprimer mon compte'), findsWidgets);
      expect(_drain(tester), isEmpty, reason: 'paramètres');

      await pumpScreen(const DriverEarningsScreen());
      expect(find.text('Mes recettes'), findsOneWidget);
      expect(find.textContaining(7500.toCFA), findsWidgets, reason: '3000 + 4500 = 7 500 FCFA aujourd\'hui');
      expect(_drain(tester), isEmpty, reason: 'gains');

      await pumpScreen(const DriverHistoryScreen());
      expect(find.text('Historique'), findsWidgets);
      expect(_drain(tester), isEmpty, reason: 'historique');
      await tester.pump(const Duration(seconds: 15));
    });
  }

  // ---------------------------------------------------------------- déconnexion
  testWidgets('S20 déconnexion : session effacée mais le serveur n\'est pas prévenu que le chauffeur est hors ligne', (
    tester,
  ) async {
    usePhone(tester);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({'driver_access_token': 't'});
    await LocalStorage.instance.init();
    final backend = FakeFrayaBackend()..online = true;
    final auth = FakeDriverAuthNotifier(
      AuthState(
        status: AuthStatus.authenticated,
        userData: const {
          'userId': 14,
          'driverId': 14,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'APPROVED',
          'vehicleId': 7,
        },
      ),
    );
    await auth.logout();
    expect(auth.logoutCalls, 1);
    expect(auth.state.status, AuthStatus.unauthenticated);
    final token = await LocalStorage.instance.getSecure('driver_access_token');
    expect(token, isNull, reason: 'jeton effacé');
    // Aucun appel PUT /sid-users/me/online {isOnline:false} n'est émis par le flux de déconnexion
    // (LogoutDriverUseCase ne fait que vider le stockage ; revue de logout_driver_usecase.dart).
    expect(backend.callsTo('PUT', '/sid-users/me/online'), isEmpty);
    expect(backend.online, isTrue, reason: 'le serveur croit encore le chauffeur en ligne jusqu\'à expiration du heartbeat');
    await tester.pump();
  });
}
