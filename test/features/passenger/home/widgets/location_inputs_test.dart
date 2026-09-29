import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/features/passenger/home/providers/address_search_sheet_focus_controller.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/search/location_inputs.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

const _currentAddress = 'Ma position actuelle';

void main() {
  testWidgets(
    'pickup clear icon disappears on edit and pickup action still resets pickup/query on tap',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _pumpLocationInputs(tester, container);

      expect(find.byIcon(Icons.my_location), findsNothing);
      expect(find.byTooltip('Vider le champ'), findsNothing);

      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      expect(find.byTooltip('Vider le champ'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Pickup manuel');
      await tester.pump();
      expect(find.byTooltip('Vider le champ'), findsNothing);
      expect(find.byIcon(Icons.my_location), findsOneWidget);

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(container.read(selectedPickupProvider), isNull);
      expect(container.read(searchQueryProvider), '');
      expect(container.read(activeSearchTypeProvider), SearchType.destination);
    },
  );

  testWidgets(
    'clear icon appears only while a prefilled pickup field is focused',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _pumpLocationInputs(tester, container);

      final pickupFinder = find.byType(TextField).first;

      expect(find.byTooltip('Vider le champ'), findsNothing);

      await tester.tap(pickupFinder);
      await tester.pump();

      expect(find.byTooltip('Vider le champ'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      final pickupField = tester.widget<TextField>(pickupFinder);
      pickupField.focusNode!.unfocus();
      await tester.pump();

      expect(find.byTooltip('Vider le champ'), findsNothing);
    },
  );

  testWidgets('clear icon does not appear on an empty destination field', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpLocationInputs(tester, container);

    await tester.tap(find.byType(TextField).last);
    await tester.pump();

    expect(find.byTooltip('Vider le champ'), findsNothing);
  });

  testWidgets('pickup clear icon empties the field and keeps focus', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpLocationInputs(tester, container);

    final pickupFinder = find.byType(TextField).first;

    await tester.tap(pickupFinder);
    await tester.pump();
    await tester.tap(find.byTooltip('Vider le champ'));
    await tester.pump();

    final pickupField = tester.widget<TextField>(pickupFinder);

    expect(pickupField.controller!.text, '');
    expect(pickupField.focusNode!.hasFocus, isTrue);
    expect(find.byTooltip('Vider le champ'), findsNothing);
    expect(container.read(selectedPickupProvider), isNull);
    expect(container.read(searchQueryProvider), '');
  });

  testWidgets('pickup field layout stays stable when clear suffix appears', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpLocationInputs(tester, container);

    final pickupFinder = find.byType(TextField).first;
    final initialRect = tester.getRect(pickupFinder);

    await tester.tap(pickupFinder);
    await tester.pump();

    final focusedRect = tester.getRect(pickupFinder);

    expect(focusedRect.top, initialRect.top);
    expect(focusedRect.height, initialRect.height);
    expect(focusedRect.width, initialRect.width);
  });

  testWidgets('destination clear icon clears a refocused existing query', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpLocationInputs(tester, container);

    final destinationFinder = find.byType(TextField).last;

    await tester.enterText(destinationFinder, 'Plateau');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byTooltip('Vider le champ'), findsNothing);

    var destinationField = tester.widget<TextField>(destinationFinder);
    destinationField.focusNode!.unfocus();
    await tester.pump();

    await tester.tap(destinationFinder);
    await tester.pump();
    expect(find.byTooltip('Vider le champ'), findsOneWidget);

    await tester.tap(find.byTooltip('Vider le champ'));
    await tester.pump();

    destinationField = tester.widget<TextField>(destinationFinder);
    expect(destinationField.controller!.text, '');
    expect(destinationField.focusNode!.hasFocus, isTrue);
    expect(container.read(selectedDestinationProvider), isNull);
    expect(container.read(searchQueryProvider), '');
  });

  testWidgets('focus request targets pickup field and selects all text', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    _setPickup(container);
    await _pumpLocationInputs(tester, container);

    container
        .read(addressSearchSheetFocusControllerProvider.notifier)
        .requestFocus(SearchType.pickup);
    await tester.pump();
    await tester.pump();

    final pickupField = tester.widget<TextField>(find.byType(TextField).first);
    final pickupController = pickupField.controller!;

    expect(pickupController.text, 'Rue 12, Cocody');
    expect(pickupField.focusNode!.hasFocus, isTrue);
    expect(pickupController.selection.baseOffset, 0);
    expect(
      pickupController.selection.extentOffset,
      pickupController.text.length,
    );
  });

  testWidgets('pickup field falls back to current address after pickup clear', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    _setPickup(container);
    await _pumpLocationInputs(tester, container);

    var pickupField = tester.widget<TextField>(find.byType(TextField).first);
    expect(pickupField.controller!.text, 'Rue 12, Cocody');

    container.read(selectedPickupProvider.notifier).clear();
    await tester.pump();

    pickupField = tester.widget<TextField>(find.byType(TextField).first);
    expect(pickupField.controller!.text, 'Ma position actuelle');
  });

  testWidgets(
    'destination confirm arrow remains visible for a selected destination',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _setDestination(container);
      await _pumpLocationInputs(tester, container);

      await tester.tap(find.byType(TextField).last);
      await tester.pump();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.byTooltip('Vider le champ'), findsNothing);
    },
  );

  testWidgets(
    'pickup field cleared while focused shows the my-location button',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _pumpLocationInputs(tester, container);

      final pickupFinder = find.byType(TextField).first;

      await tester.tap(pickupFinder);
      await tester.pump();
      await tester.tap(find.byTooltip('Vider le champ'));
      await tester.pump();

      final pickupField = tester.widget<TextField>(pickupFinder);
      expect(pickupField.controller!.text, '');
      expect(pickupField.focusNode!.hasFocus, isTrue);
      expect(find.byTooltip('Ma position actuelle'), findsOneWidget);
      expect(find.byTooltip('Vider le champ'), findsNothing);
    },
  );

  testWidgets(
    'pickup field loses focus while empty restores baseline text',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _pumpLocationInputs(tester, container);

      final pickupFinder = find.byType(TextField).first;

      await tester.tap(pickupFinder);
      await tester.pump();
      await tester.tap(find.byTooltip('Vider le champ'));
      await tester.pump();

      var pickupField = tester.widget<TextField>(pickupFinder);
      expect(pickupField.controller!.text, '');

      pickupField.focusNode!.unfocus();
      await tester.pump();

      pickupField = tester.widget<TextField>(pickupFinder);
      expect(pickupField.controller!.text, _currentAddress);
      expect(find.byTooltip('Ma position actuelle'), findsNothing);
    },
  );
}

Future<void> _pumpLocationInputs(
  WidgetTester tester,
  ProviderContainer container,
) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: LocationInputs(currentAddress: _currentAddress)),
      ),
    ),
  );
}

void _setPickup(ProviderContainer container) {
  container.read(selectedPickupProvider.notifier).setPlace(_pickupPlace);
}

void _setDestination(ProviderContainer container) {
  container
      .read(selectedDestinationProvider.notifier)
      .setPlace(_destinationPlace);
}

const _pickupPlace = PlaceDetails(
  placeId: 'pickup_1',
  name: 'Residence',
  address: 'Rue 12, Cocody',
  latitude: 5.0,
  longitude: -4.0,
);

const _destinationPlace = PlaceDetails(
  placeId: 'destination_1',
  name: 'Plateau',
  address: 'Plateau, Abidjan',
  latitude: 5.32,
  longitude: -4.02,
);
