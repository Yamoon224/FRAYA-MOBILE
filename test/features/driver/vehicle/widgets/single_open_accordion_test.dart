import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/vehicle/widgets/single_open_accordion.dart';

Widget _app({int? initialOpenIndex = 0, bool secondComplete = false}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SingleOpenAccordion(
          initialOpenIndex: initialOpenIndex,
          sections: [
            const AccordionSection(id: 'a', title: 'Section A', child: Text('Contenu A')),
            AccordionSection(
              id: 'b',
              title: 'Section B',
              isComplete: secondComplete,
              child: const Text('Contenu B'),
            ),
            const AccordionSection(id: 'c', title: 'Section C', child: Text('Contenu C')),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('la première section est ouverte par défaut, les autres fermées', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('Contenu A'), findsOneWidget);
    expect(find.text('Contenu B'), findsNothing);
    expect(find.text('Contenu C'), findsNothing);
  });

  testWidgets('une seule section peut être ouverte à la fois', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.byKey(const ValueKey('accordion-header-b')));
    await tester.pumpAndSettle();

    expect(find.text('Contenu A'), findsNothing);
    expect(find.text('Contenu B'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('accordion-header-c')));
    await tester.pumpAndSettle();

    expect(find.text('Contenu B'), findsNothing);
    expect(find.text('Contenu C'), findsOneWidget);
    expect(find.text('Contenu A'), findsNothing);
  });

  testWidgets('toucher la section ouverte la referme', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.byKey(const ValueKey('accordion-header-a')));
    await tester.pumpAndSettle();

    expect(find.text('Contenu A'), findsNothing);
  });

  testWidgets('affiche une coche sur les sections complètes', (tester) async {
    await tester.pumpWidget(_app(secondComplete: true));

    expect(find.byKey(const ValueKey('accordion-done-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('accordion-todo-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('accordion-todo-c')), findsOneWidget);
  });

  testWidgets('peut démarrer avec toutes les sections fermées', (tester) async {
    await tester.pumpWidget(_app(initialOpenIndex: null));

    expect(find.text('Contenu A'), findsNothing);
    expect(find.text('Contenu B'), findsNothing);
  });
}
