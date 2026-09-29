import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/repositories/driver_wallet_repository_impl.dart';
import 'package:fraya_mobile/data/sources/remote/driver_wallet_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_package.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_reload_result.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_transaction.dart';

class FakeDriverWalletRemoteDataSource extends DriverWalletRemoteDataSource {
  FakeDriverWalletRemoteDataSource(this.payload) : super(dio: Dio());

  final dynamic payload;
  dynamic packagesPayload;
  dynamic subscriptionPayload;
  dynamic reloadPayload;

  @override
  Future<dynamic> getReloads() async => payload;

  @override
  Future<dynamic> getPackages() async => packagesPayload;

  @override
  Future<dynamic> subscribeToPackage({
    required int sidUserId,
    required int packageId,
  }) async => subscriptionPayload;

  @override
  Future<dynamic> reloadWallet({
    required double amount,
    String? walletId,
  }) async {
    return reloadPayload;
  }
}

void main() {
  group('DriverWalletRepositoryImpl transaction mapping', () {
    test(
      'maps withdraw transaction as debit when type indicates withdraw',
      () async {
        final repository = DriverWalletRepositoryImpl(
          remoteDataSource: FakeDriverWalletRemoteDataSource({
            'data': [
              {
                'id': 'tx-1',
                'type': 'WITHDRAW',
                'amount': 2400,
                'createdAt': '2026-05-25T10:00:00.000Z',
              },
            ],
          }),
        );

        final overview = await repository.fetchWalletOverview();
        final tx = overview.transactions.single;

        expect(tx.type, DriverWalletTransactionType.withdrawal);
        expect(tx.isCredit, isFalse);
        expect(tx.title, 'Retrait');
      },
    );

    test('maps negative amount as debit even when type is missing', () async {
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: FakeDriverWalletRemoteDataSource({
          'data': [
            {
              'id': 'tx-2',
              'amount': -1800,
              'createdAt': '2026-05-25T11:00:00.000Z',
            },
          ],
        }),
      );

      final overview = await repository.fetchWalletOverview();
      final tx = overview.transactions.single;

      expect(tx.type, DriverWalletTransactionType.withdrawal);
      expect(tx.isCredit, isFalse);
      expect(tx.title, 'Retrait');
    });

    test('maps positive amount as credit when type is missing', () async {
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: FakeDriverWalletRemoteDataSource({
          'data': [
            {
              'id': 'tx-3',
              'amount': 5000,
              'createdAt': '2026-05-25T12:00:00.000Z',
            },
          ],
        }),
      );

      final overview = await repository.fetchWalletOverview();
      final tx = overview.transactions.single;

      expect(tx.type, DriverWalletTransactionType.recharge);
      expect(tx.isCredit, isTrue);
      expect(tx.title, 'Recharge');
    });

    test('maps commission type to Commission Fraya title', () async {
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: FakeDriverWalletRemoteDataSource({
          'data': [
            {
              'id': 'tx-4',
              'type': 'COMMISSION',
              'amount': 800,
              'createdAt': '2026-05-25T13:00:00.000Z',
            },
          ],
        }),
      );

      final overview = await repository.fetchWalletOverview();
      final tx = overview.transactions.single;

      expect(tx.type, DriverWalletTransactionType.commission);
      expect(tx.title, 'Commission Fraya');
    });

    test('maps package keywords to Achat package title', () async {
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: FakeDriverWalletRemoteDataSource({
          'data': [
            {
              'id': 'tx-4b',
              'type': 'PACKAGE_SUBSCRIPTION',
              'amount': 1500,
              'createdAt': '2026-05-25T13:10:00.000Z',
            },
          ],
        }),
      );

      final overview = await repository.fetchWalletOverview();
      final tx = overview.transactions.single;

      expect(tx.type, DriverWalletTransactionType.packagePurchase);
      expect(tx.isCredit, isFalse);
      expect(tx.title, 'Achat package');
    });

    test('does not map recharge to Achat package', () async {
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: FakeDriverWalletRemoteDataSource({
          'data': [
            {
              'id': 'tx-4c',
              'type': 'RELOAD',
              'description': 'Recharge wallet',
              'amount': 1500,
              'createdAt': '2026-05-25T13:20:00.000Z',
            },
          ],
        }),
      );

      final overview = await repository.fetchWalletOverview();
      final tx = overview.transactions.single;

      expect(tx.type, DriverWalletTransactionType.recharge);
      expect(tx.title, 'Recharge');
    });

    test('deduplicates two identical entries from API by reference', () async {
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: FakeDriverWalletRemoteDataSource({
          'data': [
            {
              'id': 'tx-5a',
              'reference': 'REF-001',
              'type': 'RELOAD',
              'amount': 5000,
              'createdAt': '2026-05-25T14:00:00.000Z',
            },
            {
              'id': 'tx-5b',
              'reference': 'REF-001',
              'type': 'RELOAD',
              'amount': 5000,
              'createdAt': '2026-05-25T14:00:01.000Z',
            },
          ],
        }),
      );

      final overview = await repository.fetchWalletOverview();

      expect(overview.transactions.length, 1);
      expect(overview.transactions.single.title, 'Recharge');
    });

    test('keeps two distinct recharges with different references', () async {
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: FakeDriverWalletRemoteDataSource({
          'data': [
            {
              'id': 'tx-6',
              'reference': 'REF-A',
              'type': 'RELOAD',
              'amount': 5000,
              'createdAt': '2026-05-25T14:00:00.000Z',
            },
            {
              'id': 'tx-7',
              'reference': 'REF-B',
              'type': 'RELOAD',
              'amount': 5000,
              'createdAt': '2026-05-25T15:00:00.000Z',
            },
          ],
        }),
      );

      final overview = await repository.fetchWalletOverview();

      expect(overview.transactions.length, 2);
    });

    test(
      'parses visible packages and ignores private or inactive items',
      () async {
        final dataSource = FakeDriverWalletRemoteDataSource({'data': []})
          ..packagesPayload = {
            'data': [
              {
                'id': '8',
                'name': 'Pack Journalier - Starter VTC',
                'description': 'Ideal',
                'trialDays': '0',
                'dailyPrice': '1500',
                'monthlyPrice': null,
                'annualPrice': null,
                'maxRides': '12',
                'maxCancellations': '2',
                'status': true,
                'isRecommended': false,
                'isPrivate': false,
                'type': 'standard',
                'isMonthly': false,
                'isAnnual': false,
              },
              {'id': 9, 'name': 'Private', 'status': true, 'isPrivate': true},
              {'id': 10, 'name': 'Inactive', 'status': false},
            ],
          };
        final repository = DriverWalletRepositoryImpl(
          remoteDataSource: dataSource,
        );

        final packages = await repository.fetchPackages();
        final package = packages.single;

        expect(packages, hasLength(1));
        expect(package, isA<DriverWalletPackage>());
        expect(package.id, 8);
        expect(package.dailyPrice, 1500);
        expect(package.maxRides, 12);
      },
    );

    test('parses package subscription result wallet summary', () async {
      final dataSource = FakeDriverWalletRemoteDataSource({'data': []})
        ..subscriptionPayload = {
          'success': true,
          'message': 'Souscription effectuee avec succes.',
          'data': {
            'subscription': {
              'id': 2,
              'subscribedAt': '2026-06-06T00:41:47.936Z',
              'package': {'name': 'Pack Journalier - Starter VTC'},
            },
            'wallet': {
              'previousBalance': 3100,
              'newBalance': '1600',
              'amountDebited': 1500,
              'transactionReference': 'SUB-001',
            },
          },
        };
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final result = await repository.subscribeToPackage(
        sidUserId: 19,
        packageId: 8,
      );

      expect(result.message, 'Souscription effectuee avec succes.');
      expect(result.subscriptionId, 2);
      expect(result.packageName, 'Pack Journalier - Starter VTC');
      expect(result.newBalance, 1600);
      expect(result.transactionReference, 'SUB-001');
    });

    test('parses reload result message from API payload', () async {
      final dataSource = FakeDriverWalletRemoteDataSource({'data': []})
        ..reloadPayload = {
          'success': true,
          'message': 'Rechargement initié avec succès.',
          'data': {'reference': 'REL-001'},
        };
      final repository = DriverWalletRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final result = await repository.reloadWallet(
        amount: 2500,
        walletId: 'Fra-I4JUY',
      );

      expect(result, isA<DriverWalletReloadResult>());
      expect(result.message, 'Rechargement initié avec succès.');
      expect(result.reference, 'REL-001');
    });
  });
}
