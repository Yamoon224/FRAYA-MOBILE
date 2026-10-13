import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_drawer_sections.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_home_active_ride_card_parts.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_home_incoming_request_parts.dart';
import 'package:fraya_mobile/features/driver/profile/widgets/driver_profile_header.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/driver_info_card.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/passenger_drawer_sections.dart';
import 'package:fraya_mobile/features/passenger/profile/models/profile_model.dart';
import 'package:fraya_mobile/features/passenger/profile/widgets/profile_header.dart';
import 'package:fraya_mobile/shared/models/user_stats_view_data.dart';

import '../../support/driver_test_doubles.dart';

/// Cache manager sans disque ni réseau : chaque URL échoue comme un 404.
class _FailingCacheManager extends Fake implements BaseCacheManager {
  final requestedUrls = <String>[];

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    requestedUrls.add(url);
    return Stream<FileResponse>.error(
      HttpExceptionWithStatus(404, 'Not found', uri: Uri.parse(url)),
    );
  }
}

/// Cache manager qui ne répond jamais : l'image reste en chargement.
class _PendingCacheManager extends Fake implements BaseCacheManager {
  final _controllers = <StreamController<FileResponse>>[];

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    final controller = StreamController<FileResponse>();
    _controllers.add(controller);
    return controller.stream;
  }

  Future<void> close() async {
    for (final c in _controllers) {
      await c.close();
    }
  }
}

class _Case {
  const _Case(this.name, this.url, this.fallbackIcon, this.build);

  final String name;
  final String url;
  final IconData fallbackIcon;
  final Widget Function(String? photoUrl) build;
}

final _cases = <_Case>[
  _Case(
    'DriverIdentityHeader (driver drawer)',
    'https://cdn.fraya.test/profiles/driver-drawer.jpg',
    Icons.person_outline_rounded,
    (url) => DriverIdentityHeader(
      fullName: 'Koffi Yao',
      stats: UserStatsViewData.empty,
      photoUrl: url,
    ),
  ),
  _Case(
    'DriverHomeActiveRidePassengerHeader',
    'https://cdn.fraya.test/profiles/active-ride-passenger.jpg',
    Icons.person_outline_rounded,
    (url) => DriverHomeActiveRidePassengerHeader(
      name: 'Alice Kouassi',
      photoUrl: url,
      passengerRating: 4.8,
      passengerRidesCount: 12,
      onCallPassenger: () {},
      onOpenPassengerWhatsApp: () {},
    ),
  ),
  _Case(
    'IncomingRequestContent',
    'https://cdn.fraya.test/profiles/incoming-passenger.jpg',
    Icons.person_outline_rounded,
    (url) => SizedBox(
      height: 760,
      child: IncomingRequestContent(
        ride: buildDriverRide().copyWith(passengerPhoto: url),
        pendingCount: 1,
        secondsRemaining: 20,
        isBusy: false,
        onAccept: () async {},
        onDecline: () {},
      ),
    ),
  ),
  _Case(
    'DriverProfileHeader',
    'https://cdn.fraya.test/profiles/driver-profile.jpg',
    Icons.person_outline_rounded,
    (url) => DriverProfileHeader(
      name: 'Koffi Yao',
      stats: UserStatsViewData.empty,
      photoUrl: url,
    ),
  ),
  _Case(
    'DriverInfoCard (passenger active ride)',
    'https://cdn.fraya.test/profiles/driver-info-card.jpg',
    Icons.person_outline_rounded,
    (url) => DriverInfoCard(
      ride: ActiveRide.mock.copyWith(
        driverPhoto: url ?? 'assets/images/driver_placeholder.png',
      ),
    ),
  ),
  _Case(
    'PassengerDrawerUserInfo',
    'https://cdn.fraya.test/profiles/passenger-drawer.jpg',
    Icons.person_outline,
    (url) => PassengerDrawerUserInfo(
      userData: const {'firstName': 'Awa', 'phoneNumber': '0700000000'},
      stats: UserStatsViewData.empty,
      profilePhotoUrl: url,
    ),
  ),
  _Case(
    'ProfileHeader (passenger profile)',
    'https://cdn.fraya.test/profiles/passenger-profile.jpg',
    Icons.person_outline,
    (url) => ProfileHeader(
      profile: PassengerProfile(
        firstName: 'Awa',
        lastName: 'Traoré',
        name: 'Awa Traoré',
        phone: '0700000000',
        email: 'awa@fraya.ci',
        rating: 4.9,
        ridesCount: 3,
        membershipMonths: 2,
        memberSince: '2026',
        photoUrl: url,
      ),
    ),
  ),
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.topCenter, child: child),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    AppConfig.instance.init(flavor: AppFlavor.dev);
  });

  // Le cache d'images Flutter survit d'un test à l'autre : on le vide pour
  // que chaque test reparte d'un chargement neuf.
  tearDown(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  for (final c in _cases) {
    group(c.name, () {
      testWidgets('loads the photo through CachedNetworkImage', (
        tester,
      ) async {
        final cache = _PendingCacheManager();
        CachedNetworkImageProvider.defaultCacheManager = cache;

        await _pump(tester, c.build(c.url));
        await tester.pump();

        final image = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(image.imageUrl, c.url);
        expect(image.fit, BoxFit.cover);
        expect(find.byType(Image).evaluate().where((e) {
          final w = e.widget as Image;
          return w.image is NetworkImage;
        }), isEmpty, reason: 'Image.network ne doit plus être utilisé');
        expect(
          find.descendant(
            of: find.byType(CachedNetworkImage),
            matching: find.byIcon(c.fallbackIcon),
          ),
          findsNothing,
          reason: 'pas de fallback tant que le chargement est en cours',
        );

        await cache.close();
      });

      testWidgets('falls back to the placeholder icon on error', (
        tester,
      ) async {
        final cache = _FailingCacheManager();
        CachedNetworkImageProvider.defaultCacheManager = cache;

        await _pump(tester, c.build(c.url));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1));

        expect(cache.requestedUrls, contains(c.url));
        expect(
          find.descendant(
            of: find.byType(CachedNetworkImage),
            matching: find.byIcon(c.fallbackIcon),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('shows the placeholder without network when no photo', (
        tester,
      ) async {
        final cache = _FailingCacheManager();
        CachedNetworkImageProvider.defaultCacheManager = cache;

        await _pump(tester, c.build(null));
        await tester.pump();

        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(find.byIcon(c.fallbackIcon), findsWidgets);
        expect(cache.requestedUrls, isEmpty);
      });
    });
  }
}
