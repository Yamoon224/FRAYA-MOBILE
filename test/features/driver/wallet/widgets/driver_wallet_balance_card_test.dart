import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/wallet/widgets/driver_wallet_balance_card.dart';

void main() {
  testWidgets('renders without overflow on narrow screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DriverWalletBalanceCard(
              balanceText: '123 456',
              onReloadPressed: () {},
              onSubscribePressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Solde de credit'), findsOneWidget);
    expect(find.text('Recharger'), findsOneWidget);
    expect(find.text('Retirer'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
