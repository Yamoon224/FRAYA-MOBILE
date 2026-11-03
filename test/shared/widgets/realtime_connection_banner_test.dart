import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/realtime/socket_health_state.dart';
import 'package:fraya_mobile/shared/providers/realtime_providers.dart';
import 'package:fraya_mobile/shared/widgets/realtime_connection_banner.dart';

Widget _host(ProviderContainer container, {required bool isRideActive}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: RealtimeConnectionBanner(
          isRideActive: isRideActive,
          message: kPassengerConnectionBannerMessage,
        ),
      ),
    ),
  );
}

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  void setHealth(SocketHealthState state) =>
      container.read(realtimeHealthStateProvider.notifier).state = state;

  testWidgets('visible en course quand degraded ou offline seulement', (
    tester,
  ) async {
    for (final state in SocketHealthState.values) {
      setHealth(state);
      await tester.pumpWidget(_host(container, isRideActive: true));

      final expected =
          state == SocketHealthState.degraded ||
          state == SocketHealthState.offline;
      expect(
        find.text(kPassengerConnectionBannerMessage),
        expected ? findsOneWidget : findsNothing,
        reason: state.name,
      );
    }
  });

  testWidgets('jamais affiché hors course', (tester) async {
    setHealth(SocketHealthState.offline);
    await tester.pumpWidget(_host(container, isRideActive: false));

    expect(find.text(kPassengerConnectionBannerMessage), findsNothing);
  });

  testWidgets('disparaît au retour de connected', (tester) async {
    setHealth(SocketHealthState.degraded);
    await tester.pumpWidget(_host(container, isRideActive: true));
    expect(find.text(kPassengerConnectionBannerMessage), findsOneWidget);

    setHealth(SocketHealthState.connected);
    await tester.pump();

    expect(find.text(kPassengerConnectionBannerMessage), findsNothing);
  });

  test('les textes chauffeur et passager sont distincts', () {
    expect(kDriverConnectionBannerMessage, contains('positions sont conservées'));
    expect(kPassengerConnectionBannerMessage, contains('chauffeur'));
  });
}
