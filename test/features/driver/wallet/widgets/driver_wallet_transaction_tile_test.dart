import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_transaction.dart';
import 'package:fraya_mobile/features/driver/wallet/widgets/driver_wallet_transaction_tile.dart';

void main() {
  testWidgets('renders package purchase with dedicated title and icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverWalletTransactionTile(
            transaction: DriverWalletTransaction(
              id: 'tx-package',
              title: 'Achat package',
              subtitle: 'Fraya',
              amount: 1500,
              isCredit: false,
              occurredAt: DateTime(2026, 6, 24, 10),
              type: DriverWalletTransactionType.packagePurchase,
            ),
            amountText: '-1 500 FCFA',
            dateText: '24 juin, 10:00',
          ),
        ),
      ),
    );

    expect(find.text('Achat package'), findsOneWidget);
    expect(find.byIcon(Icons.card_membership_rounded), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsNothing);
  });

  testWidgets('renders commission with dedicated title and icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverWalletTransactionTile(
            transaction: DriverWalletTransaction(
              id: 'tx-commission',
              title: 'Commission Fraya',
              subtitle: 'Fraya',
              amount: 800,
              isCredit: false,
              occurredAt: DateTime(2026, 6, 24, 11),
              type: DriverWalletTransactionType.commission,
            ),
            amountText: '-800 FCFA',
            dateText: '24 juin, 11:00',
          ),
        ),
      ),
    );

    expect(find.text('Commission Fraya'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    expect(find.byIcon(Icons.card_membership_rounded), findsNothing);
  });
}
