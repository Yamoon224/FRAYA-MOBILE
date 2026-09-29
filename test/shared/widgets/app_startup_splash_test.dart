import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/widgets/app_startup_splash.dart';

void main() {
  const childKey = ValueKey('prepared-app');
  const overlayKey = ValueKey('app-startup-splash-overlay');
  const animationKey = ValueKey('app-startup-splash-animation');

  testWidgets('shows the splash above the prepared application', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const SizedBox(key: childKey)));
    await tester.pump();

    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byKey(overlayKey), findsOneWidget);
    expect(find.byKey(animationKey), findsOneWidget);
  });

  testWidgets('removes the splash after the animation and fade', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const SizedBox(key: childKey)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byKey(overlayKey), findsNothing);
  });

  testWidgets('does not block the application when the asset fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        const SizedBox(key: childKey),
        assetPath: 'assets/images/missing_splash.json',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byKey(overlayKey), findsNothing);
  });
}

Widget _buildApp(Widget child, {String? assetPath}) {
  return MaterialApp(
    home: AppStartupSplash(
      assetPath: assetPath ?? AppStartupSplash.defaultAssetPath,
      child: child,
    ),
  );
}
