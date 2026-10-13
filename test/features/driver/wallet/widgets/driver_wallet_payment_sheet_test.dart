import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/wallet/models/driver_wallet_operation_result.dart';
import 'package:fraya_mobile/features/driver/wallet/widgets/driver_wallet_payment_sheet.dart';

Future<List<DriverWalletReloadDraft>> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final drafts = <DriverWalletReloadDraft>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DriverWalletPaymentSheet(
          title: 'Recharger le compte',
          confirmLabel: 'Confirmer le paiement',
          onSubmit: (draft) async => drafts.add(draft),
        ),
      ),
    ),
  );
  return drafts;
}

void main() {
  testWidgets(
    'offers only Orange Money until the other providers are integrated',
    (tester) async {
      await _pump(tester);

      expect(find.text('Orange Money'), findsOneWidget);
      expect(find.text('Wave'), findsNothing);
      expect(find.text('MTN MoMo'), findsNothing);
      expect(find.text('Moov Money'), findsNothing);
    },
  );

  testWidgets('submits the amount with Orange Money selected by default', (
    tester,
  ) async {
    final drafts = await _pump(tester);

    await tester.enterText(find.byType(TextField), '200');
    await tester.tap(find.text('Confirmer le paiement'));
    await tester.pumpAndSettle();

    expect(drafts, hasLength(1));
    expect(drafts.single.amount, 200);
    expect(drafts.single.paymentMethod, 'orange_money');
  });

  testWidgets('rejects an empty amount without submitting', (tester) async {
    final drafts = await _pump(tester);

    await tester.tap(find.text('Confirmer le paiement'));
    await tester.pump();

    expect(drafts, isEmpty);
    expect(find.text('Saisissez un montant valide.'), findsOneWidget);
  });
}
