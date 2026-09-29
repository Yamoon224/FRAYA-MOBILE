import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/data/sources/local/special_offer_local_data_source.dart';
import 'package:fraya_mobile/domain/repositories/passenger_profile_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/profile/providers/profile_dependencies.dart';
import 'package:fraya_mobile/features/passenger/profile/screens/passenger_profile_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/special_offer_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
  });

  testWidgets('passenger logout asks for confirmation before logout', (
    tester,
  ) async {
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(status: AuthStatus.authenticated, userData: const {'id': 15}),
    );
    await _pumpProfile(tester, authNotifier);

    await tester.scrollUntilVisible(find.text('Déconnexion'), 300);
    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter ?'), findsOneWidget);
    _expectAbove(tester, find.text('Déconnexion').last, find.text('Annuler'));

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(authNotifier.logoutCalls, 0);

    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déconnexion').last);
    await tester.pumpAndSettle();

    expect(authNotifier.logoutCalls, 1);
  });

  testWidgets('profile promotions menu shows active passenger offer count', (
    tester,
  ) async {
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(status: AuthStatus.authenticated, userData: const {'id': 15}),
    );
    await _pumpProfile(
      tester,
      authNotifier,
      offers: [
        _offerMap(id: 'passenger-1', audiences: const ['passenger']),
        _offerMap(id: 'shared', audiences: const ['passenger', 'driver']),
        _offerMap(
          id: 'inactive-passenger',
          audiences: const ['passenger'],
          isActive: false,
        ),
        _offerMap(id: 'driver-only', audiences: const ['driver']),
      ],
    );

    await tester.scrollUntilVisible(find.text('Offres & Promotions'), 300);

    expect(find.text('Offres & Promotions'), findsOneWidget);
    expect(_badgeText('2'), findsOneWidget);
  });

  testWidgets('profile promotions menu hides badge when no passenger offer', (
    tester,
  ) async {
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(status: AuthStatus.authenticated, userData: const {'id': 15}),
    );
    await _pumpProfile(
      tester,
      authNotifier,
      offers: [
        _offerMap(
          id: 'inactive',
          audiences: const ['passenger'],
          isActive: false,
        ),
        _offerMap(id: 'driver-only', audiences: const ['driver']),
      ],
    );

    await tester.scrollUntilVisible(find.text('Offres & Promotions'), 300);

    expect(find.text('Offres & Promotions'), findsOneWidget);
    expect(_badgeText('0'), findsNothing);
    expect(_badgeText('3'), findsNothing);
  });
}

Future<void> _pumpProfile(
  WidgetTester tester,
  _PassengerAuthNotifierFake authNotifier, {
  List<Map<String, dynamic>> offers = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        passengerAuthProvider.overrideWith((ref) => authNotifier),
        profileRepositoryProvider.overrideWith(
          (ref) => _PassengerProfileRepositoryFake(),
        ),
        specialOfferLocalDataSourceProvider.overrideWithValue(
          SpecialOfferLocalDataSource(
            loadConfig: (_) async => jsonEncode(offers),
          ),
        ),
      ],
      child: const MaterialApp(home: MyPassengerProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _PassengerProfileRepositoryFake implements PassengerProfileRepository {
  @override
  Future<Map<String, dynamic>> getProfile() async {
    return const {
      'data': {
        'id': 15,
        'firstNames': 'Awa',
        'lastName': 'Kone',
        'phoneNumber': '0700000000',
        'email': 'awa@test.com',
      },
    };
  }

  @override
  Future<void> requestPhoneChange(String newPhoneNumber) {
    fail('Unexpected request phone change call.');
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  }) {
    fail('Unexpected profile update call.');
  }

  @override
  Future<Map<String, dynamic>> updateProfilePhoto({
    required int userId,
    required String filePath,
    required String fileName,
  }) {
    fail('Unexpected profile photo update call.');
  }

  @override
  Future<void> confirmPhoneChange(String verificationCode) {
    fail('Unexpected confirm phone change call.');
  }
}

class _PassengerAuthNotifierFake extends PassengerAuthNotifier {
  _PassengerAuthNotifierFake(AuthState initialState)
    : super(
        loginUsecase: LoginPassengerUsecase(_PassengerAuthRepositoryFake()),
        registerStep1Usecase: RegisterStep1Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        registerStep2Usecase: RegisterStep2Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        registerStep3Usecase: RegisterStep3Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        logoutUsecase: LogoutPassengerUsecase(),
      ) {
    state = initialState;
  }

  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

class _PassengerAuthRepositoryFake extends PassengerAuthRepository {
  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String password) {
    fail('Unexpected passenger login call.');
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) {
    fail('Unexpected passenger register step 1 call.');
  }

  @override
  Future<void> registerStep2(String phoneNumber, String verificationCode) {
    fail('Unexpected passenger register step 2 call.');
  }

  @override
  Future<Map<String, dynamic>> registerStep3(Map<String, dynamic> userData) {
    fail('Unexpected passenger register step 3 call.');
  }
}

Map<String, dynamic> _offerMap({
  required String id,
  List<String> audiences = const ['passenger'],
  bool isActive = true,
}) {
  return {
    'id': id,
    'title': 'Offre $id',
    'description': 'Description $id',
    'isActive': isActive,
    'audiences': audiences,
  };
}

Finder _badgeText(String value) {
  return find.byWidgetPredicate((widget) {
    return widget is Text &&
        widget.data == value &&
        widget.style?.fontSize == 10 &&
        widget.style?.fontWeight == FontWeight.bold;
  });
}

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}
