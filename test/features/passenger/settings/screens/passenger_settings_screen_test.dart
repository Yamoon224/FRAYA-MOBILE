import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/repositories/account_deletion_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/settings/screens/passenger_settings_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/account_deletion_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
  });

  testWidgets('renders settings groups and account actions', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PassengerSettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Préférences'), findsOneWidget);
    expect(find.text('Sécurité & Confidentialité'), findsOneWidget);
    expect(find.text('Paiement'), findsOneWidget);
  });

  testWidgets('account deletion action opens confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PassengerSettingsScreen())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Supprimer mon compte'), 300);
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer le compte ?'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
    _expectAbove(tester, find.text('Supprimer'), find.text('Annuler'));
  });

  testWidgets('cancelling account deletion does not call repository', (
    tester,
  ) async {
    final repository = _AccountDeletionRepositoryFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(home: PassengerSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Supprimer mon compte'), 300);
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 0);
  });

  testWidgets('confirming account deletion calls repository', (tester) async {
    final repository = _AccountDeletionRepositoryFake();
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(status: AuthStatus.authenticated, userData: const {'id': 15}),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionRepositoryProvider.overrideWith((ref) => repository),
          passengerAuthProvider.overrideWith((ref) => authNotifier),
        ],
        child: const MaterialApp(home: PassengerSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Supprimer mon compte'), 300);
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();

    expect(repository.deletedUserId, 15);
    expect(authNotifier.logoutCalls, 1);
  });
}

class _AccountDeletionRepositoryFake implements AccountDeletionRepository {
  int deleteCalls = 0;
  int? deletedUserId;

  @override
  Future<void> deleteAccount(int userId) async {
    deleteCalls++;
    deletedUserId = userId;
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

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}
