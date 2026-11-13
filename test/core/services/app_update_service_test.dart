import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fraya_mobile/core/services/app_update_service.dart';

void main() {
  group('compareVersions', () {
    test('reconnaît une version plus récente, identique ou plus ancienne', () {
      expect(compareVersions('1.0.6', '1.0.5'), greaterThan(0));
      expect(compareVersions('1.1.0', '1.0.9'), greaterThan(0));
      expect(compareVersions('2.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.0.5', '1.0.5'), 0);
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1.0.4', '1.0.5'), lessThan(0));
    });

    test('ignore le numéro de build après le +', () {
      expect(compareVersions('1.0.5+16', '1.0.5+15'), 0);
    });

    test('compare les nombres et non les chaînes (1.0.10 > 1.0.9)', () {
      expect(compareVersions('1.0.10', '1.0.9'), greaterThan(0));
    });
  });

  group('rappel « Plus tard »', () {
    const update = AvailableUpdate(storeVersion: '1.0.6');
    final base = DateTime(2026, 11, 3, 10);

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('propose la mise à jour tant que rien n\'a été repoussé', () async {
      expect(await AppUpdateService().shouldPrompt(update), isTrue);
    });

    test('ne repropose pas la même version avant 24 h', () async {
      final service = AppUpdateService();
      await service.snooze(update, now: base);
      expect(
        await service.shouldPrompt(
          update,
          now: base.add(const Duration(hours: 23)),
        ),
        isFalse,
      );
      expect(
        await service.shouldPrompt(
          update,
          now: base.add(const Duration(hours: 24)),
        ),
        isTrue,
      );
    });

    test('repropose tout de suite une version encore plus récente', () async {
      final service = AppUpdateService();
      await service.snooze(update, now: base);
      expect(
        await service.shouldPrompt(
          const AvailableUpdate(storeVersion: '1.0.7'),
          now: base.add(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });
  });

  group("détection sur l'App Store (iOS)", () {
    String lookup(String version) => jsonEncode({
      'resultCount': 1,
      'results': [
        {
          'version': version,
          'trackViewUrl':
              'https://apps.apple.com/ci/app/fraya-taxi/id6825035633',
        },
      ],
    });

    test(
      "lit la réponse « text/javascript » d'iTunes (non décodée par Dio)",
      () async {
        final adapter = _FakeItunesAdapter({'ci': lookup('1.0.7')});
        final service = AppUpdateService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        final update = await service.checkIos(
          bundleId: 'com.carrementweb.frayaMobile.passenger',
          currentVersion: '1.0.6',
        );

        expect(update, isNotNull);
        expect(update!.storeVersion, '1.0.7');
        expect(update.storeUrl, contains('apps.apple.com'));
      },
    );

    test(
      'ne propose rien quand la version installée est à jour ou plus récente',
      () async {
        final adapter = _FakeItunesAdapter({'ci': lookup('1.0.6')});
        final service = AppUpdateService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        expect(
          await service.checkIos(bundleId: 'b', currentVersion: '1.0.6'),
          isNull,
        );
        expect(
          await service.checkIos(bundleId: 'b', currentVersion: '1.0.9'),
          isNull,
        );
      },
    );

    test(
      "retombe sur la recherche mondiale si l'app n'est pas listée en Côte d'Ivoire",
      () async {
        final adapter = _FakeItunesAdapter({
          'ci': jsonEncode({'resultCount': 0, 'results': []}),
          'world': lookup('1.0.7'),
        });
        final service = AppUpdateService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        final update = await service.checkIos(
          bundleId: 'b',
          currentVersion: '1.0.6',
        );

        expect(update?.storeVersion, '1.0.7');
        expect(adapter.countries, ['ci', null]);
      },
    );

    test(
      'ajoute un paramètre unique pour contourner le cache du CDN',
      () async {
        final adapter = _FakeItunesAdapter({'ci': lookup('1.0.7')});
        final service = AppUpdateService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        await service.checkIos(bundleId: 'b', currentVersion: '1.0.6');

        expect(adapter.lastQuery.containsKey('t'), isTrue);
        expect(adapter.lastQuery['bundleId'], 'b');
      },
    );

    test('une réponse vide ou illisible ne propose rien', () async {
      final adapter = _FakeItunesAdapter({'ci': '{}', 'world': '{}'});
      final service = AppUpdateService(dio: Dio()..httpClientAdapter = adapter);

      expect(
        await service.checkIos(bundleId: 'b', currentVersion: '1.0.6'),
        isNull,
      );
    });
  });
}

/// Imite iTunes : le corps est du JSON mais le type de contenu est « text/javascript ».
class _FakeItunesAdapter implements HttpClientAdapter {
  _FakeItunesAdapter(this.bodies);

  /// Clés : 'ci' (boutique ivoirienne) ou 'world' (sans paramètre country).
  final Map<String, String> bodies;
  final List<String?> countries = [];
  Map<String, dynamic> lastQuery = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastQuery = Map.of(options.queryParameters);
    final country = options.queryParameters['country'] as String?;
    countries.add(country);
    final body = bodies[country ?? 'world'] ?? '{}';
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/javascript; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
