import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/core/services/special_offer_share_service.dart';
import 'package:fraya_mobile/data/sources/local/special_offer_local_data_source.dart';
import 'package:fraya_mobile/domain/models/special_offer.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/passenger_drawer.dart';
import 'package:fraya_mobile/features/passenger/profile/models/profile_model.dart';
import 'package:fraya_mobile/features/passenger/profile/providers/profile_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/special_offer_dependencies.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('navigates to settings route from drawer settings item', (
    tester,
  ) async {
    final shareSpy = _ShareSpy();

    await _pumpDrawer(tester, offers: [_offerMap()], shareSpy: shareSpy);

    await tester.tap(find.textContaining('Param'));
    await tester.pumpAndSettle();

    expect(find.text('settings-page'), findsOneWidget);
  });

  testWidgets('hides the special offer section when no offer is configured', (
    tester,
  ) async {
    await _pumpDrawer(tester, offers: const []);

    expect(find.text('OFFRE SPECIALE'), findsNothing);
    expect(find.text('Invitez vos proches'), findsNothing);
  });

  testWidgets(
    'shares the active passenger offer without navigating to promotions',
    (tester) async {
      final shareSpy = _ShareSpy();

      await _pumpDrawer(tester, offers: [_offerMap()], shareSpy: shareSpy);

      expect(find.text('OFFRE SPECIALE'), findsOneWidget);
      expect(find.text('Invitez vos proches'), findsOneWidget);

      await tester.tap(find.text('Partager'));
      await tester.pumpAndSettle();

      expect(
        shareSpy.sharedText,
        'Invitez vos proches\n\nPartagez Fraya avec votre entourage.',
      );
      expect(shareSpy.sharedSubject, 'Invitez vos proches');
      expect(find.text('promotions-page'), findsNothing);
    },
  );

  testWidgets('shows the passenger profile photo from loaded profile', (
    tester,
  ) async {
    await _pumpDrawer(
      tester,
      offers: const [],
      profile: _profile(photoUrl: '/uploads/passenger.jpg'),
    );

    final networkImageUrls = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<NetworkImage>()
        .map((image) => image.url);

    expect(
      networkImageUrls,
      contains('http://83.228.247.227/profiles/passenger.jpg'),
    );
  });
}

Future<void> _pumpDrawer(
  WidgetTester tester, {
  required List<Map<String, dynamic>> offers,
  _ShareSpy? shareSpy,
  PassengerProfile? profile,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  FlutterSecureStorage.setMockInitialValues({
    'access_token': 'passenger-token',
    'auth_user_data': '{"id":7,"firstNames":"Awa"}',
  });
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          drawer: const PassengerDrawer(),
          body: const SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) =>
            const Scaffold(body: Text('settings-page')),
      ),
      GoRoute(
        path: RoutePaths.promotions,
        builder: (context, state) =>
            const Scaffold(body: Text('promotions-page')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        passengerAuthProvider.overrideWith(
          (ref) => _TestPassengerAuthNotifier(_authenticatedState()),
        ),
        passengerProfileProvider.overrideWith(
          (ref) async => profile ?? _profile(),
        ),
        specialOfferLocalDataSourceProvider.overrideWithValue(
          SpecialOfferLocalDataSource(
            loadConfig: (_) async => jsonEncode(offers),
          ),
        ),
        if (shareSpy != null)
          specialOfferShareServiceProvider.overrideWithValue(shareSpy.service),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
}

AuthState _authenticatedState() {
  return AuthState(
    status: AuthStatus.authenticated,
    userData: {'id': 7, 'firstNames': 'Awa', 'phoneNumber': '0700000000'},
  );
}

PassengerProfile _profile({String? photoUrl}) {
  return PassengerProfile(
    firstName: 'Awa',
    lastName: 'Kouassi',
    name: 'Awa Kouassi',
    phone: '0700000000',
    email: 'awa@test.com',
    rating: 4.8,
    ridesCount: 12,
    membershipMonths: 3,
    memberSince: 'Mars 2026',
    photoUrl: photoUrl,
  );
}

Map<String, dynamic> _offerMap({
  Set<SpecialOfferAudience> audiences = const {
    SpecialOfferAudience.passenger,
    SpecialOfferAudience.driver,
  },
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

class _TestPassengerAuthNotifier extends PassengerAuthNotifier {
  _TestPassengerAuthNotifier(AuthState initialState)
    : super(
        loginUsecase: LoginPassengerUsecase(PassengerAuthRepository()),
        registerStep1Usecase: RegisterStep1Usecase(PassengerAuthRepository()),
        registerStep2Usecase: RegisterStep2Usecase(PassengerAuthRepository()),
        registerStep3Usecase: RegisterStep3Usecase(PassengerAuthRepository()),
        logoutUsecase: LogoutPassengerUsecase(),
      ) {
    state = initialState;
  }

  @override
  set state(AuthState value) {
    super.state = value;
  }
}
