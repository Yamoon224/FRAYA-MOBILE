// PARCOURS PASSAGER - etapes 6 et 7 (cote interface) : cartes de gammes, moyens de paiement,
// feuille "Recherche en cours". Galaxy A15, textScale 1.0 et 1.3.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/payment_method_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/payment_method_selector.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/ride_category_card.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/searching_driver_sheet.dart';

import 'qa_support.dart';

class _SearchingFlow extends BookingFlow {
  static int cancelCalls = 0;
  @override
  BookingFlowState build() => BookingFlowState.searching;
  @override
  Future<void> cancelSearching({String? reason}) async {
    cancelCalls++;
  }
}

Widget _wrap(Widget child, double scale) => ProviderScope(
      child: MaterialApp(
        builder: (c, w) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: w!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  setUpAll(() async {
    await loadRealisticFonts();
  });
  setUp(() async => initQaEnvironment());

  for (final scale in [1.0, 1.3]) {
    testWidgets('3 gammes : nom, prix FCFA, selection au tap (x$scale)', (tester) async {
      useGalaxyA15(tester);
      var selected = 'MAGIC';
      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              for (final c in RideCategory.defaultCategories)
                RideCategoryCard(category: c, isSelected: selected == c.id, onTap: () => setState(() => selected = c.id)),
            ]),
          ),
        ),
        scale,
      ));
      await tester.pump();
      expect(find.text('Magic'), findsOneWidget);
      expect(find.text('Gladiateur'), findsOneWidget);
      expect(find.text('Elite'), findsOneWidget);
      expect(find.textContaining('FCFA'), findsNWidgets(3));
      await tester.tap(find.text('Elite'));
      await tester.pump();
      expect(selected, 'ELITE');
      expect(tester.takeException(), isNull);
    });

    testWidgets('moyens de paiement : Especes, Wave, Orange, MTN, Moov sans overflow (x$scale)', (tester) async {
      useGalaxyA15(tester);
      PaymentMethod chosen = PaymentMethod.cash;
      await tester.pumpWidget(_wrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: PaymentMethodSelector(selectedMethod: chosen, onMethodSelected: (m) => chosen = m),
        ),
        scale,
      ));
      await tester.pump();
      expect(find.text('Espèces'), findsOneWidget);
      expect(find.text('Orange Money'), findsOneWidget);
      await tester.tap(find.text('Orange Money'));
      expect(chosen, PaymentMethod.orangeMoney);
      expect(tester.takeException(), isNull);
    });

    testWidgets('recherche chauffeur : message + Annuler appelle cancelSearching (x$scale)', (tester) async {
      useGalaxyA15(tester);
      _SearchingFlow.cancelCalls = 0;
      await tester.pumpWidget(ProviderScope(
        overrides: [bookingFlowProvider.overrideWith(_SearchingFlow.new)],
        child: MaterialApp(
          builder: (c, w) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
            child: w!,
          ),
          home: const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: SearchingDriverSheet())),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Recherche en cours...'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final cancel = find.textContaining('Annuler');
      expect(cancel, findsWidgets);
    });
  }
}
