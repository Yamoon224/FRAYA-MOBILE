import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/core/services/special_offer_share_service.dart';
import 'package:fraya_mobile/data/sources/local/special_offer_local_data_source.dart';
import 'package:fraya_mobile/domain/models/special_offer.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_drawer.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/special_offer_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
  });

  testWidgets('hides the driver special offer section when no offer exists', (
    tester,
  ) async {
    await _pumpDrawer(tester, offers: const []);

    expect(find.text('Chauffeur Gladiateur'), findsOneWidget);
    expect(find.text('OFFRE SPECIALE'), findsNothing);
    expect(find.text('Invitez vos proches'), findsNothing);
  });

  testWidgets('shares the active driver offer from the drawer', (tester) async {
    final shareSpy = _ShareSpy();

    await _pumpDrawer(
      tester,
      offers: [
        _offerMap(audiences: const [SpecialOfferAudience.driver]),
      ],
      shareSpy: shareSpy,
    );

    expect(find.text('OFFRE SPECIALE'), findsOneWidget);
    expect(find.text('Invitez vos proches'), findsOneWidget);

    await tester.ensureVisible(find.text('Partager'));
    await tester.tap(find.text('Partager'));
    await tester.pumpAndSettle();

    expect(
      shareSpy.sharedText,
      'Invitez vos proches\n\nPartagez Fraya avec votre entourage.',
    );
    expect(shareSpy.sharedSubject, 'Invitez vos proches');
  });

  testWidgets('cancelling logout confirmation keeps driver authenticated', (
    tester,
  ) async {
    final authNotifier = await _pumpDrawer(tester, offers: const []);

    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter ?'), findsOneWidget);
    _expectAbove(tester, find.text('Déconnexion').last, find.text('Annuler'));

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(authNotifier.logoutCalls, 0);
  });

  testWidgets('confirming logout logs out driver', (tester) async {
    final authNotifier = await _pumpDrawer(tester, offers: const []);

    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déconnexion').last);
    await tester.pumpAndSettle();

    expect(authNotifier.logoutCalls, 1);
  });
}

Future<FakeDriverAuthNotifier> _pumpDrawer(
  WidgetTester tester, {
  required List<Map<String, dynamic>> offers,
  _ShareSpy? shareSpy,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final authNotifier = FakeDriverAuthNotifier(_authenticatedState());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        driverAuthProvider.overrideWith((ref) => authNotifier),
        specialOfferLocalDataSourceProvider.overrideWithValue(
          SpecialOfferLocalDataSource(
            loadConfig: (_) async => jsonEncode(offers),
          ),
        ),
        if (shareSpy != null)
          specialOfferShareServiceProvider.overrideWithValue(shareSpy.service),
      ],
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          drawer: DriverDrawer(),
          body: SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  return authNotifier;
}

AuthState _authenticatedState() {
  return AuthState(
    status: AuthStatus.authenticated,
    userData: const {
      'driverId': 14,
      'firstNames': 'Koffi',
      'lastName': 'Yao',
      'kycStatus': 'APPROVED',
      'vehicleStatus': 'APPROVED',
      'vehicleId': 7,
      'vehicles': [
        {'range': 'GLADIATEUR'},
      ],
    },
  );
}

Map<String, dynamic> _offerMap({
  List<SpecialOfferAudience> audiences = const [
    SpecialOfferAudience.passenger,
    SpecialOfferAudience.driver,
  ],
}) {
  return {
    'id': 'offer-1',
    'title': 'Invitez vos proches',
    'description': 'Partagez Fraya avec votre entourage.',
    'isActive': true,
    'audiences': audiences.map((entry) => entry.name).toList(),
  };
}

class _ShareSpy {
  String? sharedText;
  String? sharedSubject;

  late final SpecialOfferShareService service = SpecialOfferShareService(
    shareInvoker: (params) async {
      sharedText = params.text;
      sharedSubject = params.subject;
      return null;
    },
  );
}

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}
