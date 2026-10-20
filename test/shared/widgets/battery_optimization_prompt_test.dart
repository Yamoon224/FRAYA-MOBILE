import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/battery_optimization_service.dart';
import 'package:fraya_mobile/shared/widgets/battery_optimization_prompt.dart';

class _FakeBattery implements BatteryOptimizationService {
  _FakeBattery({this.exempt = false});

  final bool exempt;
  int settingsOpened = 0;

  @override
  Future<bool> isIgnoringOptimizations() async => exempt;

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const Scaffold();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('passager : message dédié, ouverture des réglages, une seule fois', (tester) async {
    final battery = _FakeBattery();
    final context = await _pumpHost(tester);

    final first = maybeShowBatteryOptimizationPrompt(
      context,
      service: battery,
      content: BatteryPromptContent.passenger,
    );
    await tester.pumpAndSettle();
    expect(find.text(BatteryPromptContent.passenger.title), findsOneWidget);

    await tester.tap(find.text('Ouvrir les réglages'));
    await tester.pumpAndSettle();
    await first;
    expect(battery.settingsOpened, 1);

    await maybeShowBatteryOptimizationPrompt(
      context,
      service: battery,
      content: BatteryPromptContent.passenger,
    );
    await tester.pumpAndSettle();
    expect(find.text(BatteryPromptContent.passenger.title), findsNothing);
  });

  testWidgets('chauffeur et passager mémorisent séparément', (tester) async {
    final battery = _FakeBattery();
    final context = await _pumpHost(tester);

    final passenger = maybeShowBatteryOptimizationPrompt(
      context,
      service: battery,
      content: BatteryPromptContent.passenger,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    await passenger;

    final driver = maybeShowBatteryOptimizationPrompt(context, service: battery);
    await tester.pumpAndSettle();
    expect(find.text(BatteryPromptContent.driver.title), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    await driver;
  });

  testWidgets("rien n'est affiché si l'app est déjà exemptée", (tester) async {
    final context = await _pumpHost(tester);

    await maybeShowBatteryOptimizationPrompt(
      context,
      service: _FakeBattery(exempt: true),
      content: BatteryPromptContent.passenger,
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
