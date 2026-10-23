import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/navigation_launcher_service.dart';
import 'package:fraya_mobile/core/services/navigation_sdk_service.dart';

class _FakeGateway implements NavigationSdkGateway {
  _FakeGateway({
    this.termsAccepted = true,
    this.initializeError,
    List<NavigationSdkRouteResult>? routeResults,
  }) : routeResults = routeResults ?? [NavigationSdkRouteResult.ok];

  final bool termsAccepted;
  final Object? initializeError;
  final List<NavigationSdkRouteResult> routeResults;
  final calls = <String>[];

  @override
  Future<bool> ensureTermsAccepted() async {
    calls.add('terms');
    return termsAccepted;
  }

  @override
  Future<void> initializeSession() async {
    calls.add('initialize');
    if (initializeError != null) throw initializeError!;
  }

  @override
  Future<NavigationSdkRouteResult> setDestination(
    NavigationTarget target,
  ) async {
    calls.add('destination');
    return routeResults.length > 1
        ? routeResults.removeAt(0)
        : routeResults.first;
  }

  @override
  Future<void> startGuidance() async => calls.add('guidance');

  @override
  Future<void> setVoiceEnabled(bool enabled) async =>
      calls.add('voice:$enabled');

  @override
  Stream<void> get onArrival => const Stream.empty();

  @override
  Future<void> stopAndCleanup() async => calls.add('cleanup');
}

const _target = NavigationTarget(
  leg: DriverNavigationLeg.toPickup,
  latitude: 5.35,
  longitude: -4.02,
  label: 'Cocody',
);

NavigationSdkStarter _starter(_FakeGateway gateway, {int retries = 5}) =>
    NavigationSdkStarter(
      gateway: gateway,
      retryDelay: Duration.zero,
      maxLocationRetries: retries,
    );

void main() {
  group('NavigationSdkStarter.prepare', () {
    test('accepte les conditions puis ouvre la session', () async {
      final gateway = _FakeGateway();

      expect(await _starter(gateway).prepare(), isNull);
      expect(gateway.calls, ['terms', 'initialize']);
    });

    test(
      "n'ouvre pas la session quand les conditions Google sont refusées",
      () async {
        final gateway = _FakeGateway(termsAccepted: false);

        expect(
          await _starter(gateway).prepare(),
          NavigationSdkStartResult.termsRefused,
        );
        expect(gateway.calls, ['terms']);
      },
    );

    test("signale une erreur quand la session ne peut pas s'ouvrir", () async {
      final gateway = _FakeGateway(
        initializeError: StateError('clé non autorisée'),
      );

      expect(await _starter(gateway).prepare(), NavigationSdkStartResult.error);
    });
  });

  group('NavigationSdkStarter.start', () {
    test("définit la destination puis lance le guidage", () async {
      final gateway = _FakeGateway();

      expect(
        await _starter(gateway).start(_target),
        NavigationSdkStartResult.started,
      );
      expect(gateway.calls, ['destination', 'guidance']);
    });

    test("réessaie tant que la position n'est pas connue", () async {
      final gateway = _FakeGateway(
        routeResults: [
          NavigationSdkRouteResult.locationUnavailable,
          NavigationSdkRouteResult.locationUnavailable,
          NavigationSdkRouteResult.ok,
        ],
      );

      expect(
        await _starter(gateway).start(_target),
        NavigationSdkStartResult.started,
      );
      expect(gateway.calls, [
        'destination',
        'destination',
        'destination',
        'guidance',
      ]);
    });

    test(
      'abandonne après le nombre maximal de tentatives sans position',
      () async {
        final gateway = _FakeGateway(
          routeResults: [NavigationSdkRouteResult.locationUnavailable],
        );

        expect(
          await _starter(gateway, retries: 2).start(_target),
          NavigationSdkStartResult.routeUnavailable,
        );
        expect(gateway.calls.where((c) => c == 'destination'), hasLength(3));
        expect(gateway.calls, isNot(contains('guidance')));
      },
    );

    test('ne réessaie pas quand la route est refusée', () async {
      final gateway = _FakeGateway(
        routeResults: [NavigationSdkRouteResult.failed],
      );

      expect(
        await _starter(gateway).start(_target),
        NavigationSdkStartResult.routeUnavailable,
      );
      expect(gateway.calls, ['destination']);
    });
  });
}
