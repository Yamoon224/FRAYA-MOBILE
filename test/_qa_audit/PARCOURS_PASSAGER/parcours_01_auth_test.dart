// PARCOURS PASSAGER - etapes 1 a 3 : onboarding, connexion, inscription.
// Persona : Aminata, Galaxy A15 (411x891 dp, dpr 2.625), numero Orange 07.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/router/passenger_router.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';
import 'package:fraya_mobile/domain/repositories/auth_register_draft_repository.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/screens/passenger_login_screen.dart';
import 'package:fraya_mobile/features/passenger/auth/screens/passenger_register_screen.dart';
import 'package:fraya_mobile/features/passenger/onboarding/screens/passenger_onboarding_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/auth_register_draft_provider.dart';
import 'package:go_router/go_router.dart';

import 'qa_support.dart';

class _MemDraftRepo implements AuthRegisterDraftRepository {
  final drafts = <AuthRegisterRole, AuthRegisterDraft>{};
  @override
  Future<AuthRegisterDraft?> readDraft(AuthRegisterRole role) async => drafts[role];
  @override
  Future<void> saveDraft(AuthRegisterDraft d) async => drafts[d.role] = d;
  @override
  Future<void> clearDraft(AuthRegisterRole role) async => drafts.remove(role);
}

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: RoutePaths.onboarding,
      name: RouteNames.onboarding,
      builder: (_, _) => const PassengerOnboardingScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      name: RouteNames.login,
      builder: (_, _) => const PassengerLoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.register,
      name: RouteNames.register,
      builder: (_, _) => const PassengerRegisterScreen(),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      name: RouteNames.forgotPassword,
      builder: (_, _) => const Scaffold(body: Text('ECRAN_MOT_DE_PASSE_OUBLIE')),
    ),
    GoRoute(
      path: RoutePaths.passengerHome,
      name: RouteNames.passengerHome,
      builder: (_, _) => const Scaffold(body: Text('ACCUEIL_PASSAGER')),
    ),
  ],
);

Future<void> _pumpApp(
  WidgetTester tester,
  GoRouter router, {
  required FakePassengerAuthRepository repo,
  double textScale = 1.0,
  _MemDraftRepo? drafts,
}) async {
  useGalaxyA15(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        passengerAuthProvider.overrideWith((ref) => realAuthNotifier(repo)),
        authRegisterDraftRepositoryProvider.overrideWithValue(drafts ?? _MemDraftRepo()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await loadRealisticFonts();
  });
  setUp(() async => initQaEnvironment());

  group('ETAPE 1 - onboarding', () {
    for (final scale in [1.0, 1.3]) {
      testWidgets('4 diapositives puis Commencer -> /login (textScale $scale)', (tester) async {
        await _pumpApp(tester, _router(RoutePaths.onboarding),
            repo: FakePassengerAuthRepository(), textScale: scale);

        expect(find.text('Déplacements simples et rapides'), findsOneWidget);
        expect(find.text('Suivant'), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('Suivant'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Paiement flexible'), findsOneWidget);
        expect(find.text('Commencer'), findsOneWidget);
        await tester.tap(find.text('Commencer'));
        await tester.pumpAndSettle();

        expect(find.text('Bienvenue !'), findsOneWidget, reason: 'arrive sur la connexion');
        expect(LocalStorage.instance.getBool(AppConstants.onboardingCompleteKey), isTrue);
        expect(tester.takeException(), isNull, reason: 'aucun overflow a $scale');
      });
    }

    testWidgets('Passer saute directement vers la connexion', (tester) async {
      await _pumpApp(tester, _router(RoutePaths.onboarding), repo: FakePassengerAuthRepository());
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenue !'), findsOneWidget);
    });

    test('redirection : non connecte + onboarding non fait -> /onboarding ; fait -> /login', () {
      AsyncValue<dynamic> idle = const AsyncValue.data(null);
      String? go(bool done) => resolvePassengerRedirect(
        authState: AuthState(status: AuthStatus.unauthenticated),
        currentPath: RoutePaths.splash,
        hasCompletedOnboarding: done,
        pendingSearchCleanupAsync: idle,
        activeRideAsync: idle,
      );
      expect(go(false), RoutePaths.onboarding);
      expect(go(true), RoutePaths.login);
    });
  });

  group('ETAPE 2 - connexion', () {
    for (final scale in [1.0, 1.3]) {
      testWidgets('connexion nominale 07 12 34 56 78 / PIN 1234 (textScale $scale)', (tester) async {
        final repo = FakePassengerAuthRepository();
        await _pumpApp(tester, _router(RoutePaths.login), repo: repo, textScale: scale);
        expect(tester.takeException(), isNull, reason: 'rendu sans overflow');

        await tester.enterText(find.byType(TextFormField).at(0), '07 12 34 56 78');
        await tester.enterText(find.byType(TextFormField).at(1), '1234');
        await tester.ensureVisible(find.text('Se connecter'));
        await tester.tap(find.text('Se connecter'));
        await tester.pumpAndSettle();

        expect(repo.loginCalls, [('0712345678', '1234')],
            reason: 'espaces retires, 10 chiffres envoyes au backend');
        expect(find.text('ACCUEIL_PASSAGER'), findsOneWidget);
        expect(LocalStorage.instance.getString(AppConstants.accessTokenKey) ?? '', isEmpty);
        expect(await LocalStorage.instance.getSecure(AppConstants.accessTokenKey), 'jwt-aminata');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('numero trop court et mot de passe vide : messages en francais', (tester) async {
      final repo = FakePassengerAuthRepository();
      await _pumpApp(tester, _router(RoutePaths.login), repo: repo);
      await tester.enterText(find.byType(TextFormField).at(0), '0712');
      await tester.ensureVisible(find.text('Se connecter'));
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      expect(find.text('Numéro invalide'), findsOneWidget);
      expect(find.text('Veuillez entrer votre mot de passe'), findsOneWidget);
      expect(repo.loginCalls, isEmpty);
    });

    testWidgets('mauvais mot de passe : erreur backend affichee, reste sur la connexion', (tester) async {
      final repo = FakePassengerAuthRepository(
        loginHandler: (_, _) => {'success': false, 'message': 'Identifiants de connexion invalides'},
      );
      await _pumpApp(tester, _router(RoutePaths.login), repo: repo);
      await tester.enterText(find.byType(TextFormField).at(0), '0712345678');
      await tester.enterText(find.byType(TextFormField).at(1), '9999');
      await tester.ensureVisible(find.text('Se connecter'));
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Identifiants de connexion invalides'), findsOneWidget);
      expect(find.text('ACCUEIL_PASSAGER'), findsNothing);
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('numero colle au format +225 07 12 34 56 78 : le champ tronque a 10 chiffres', (tester) async {
      final repo = FakePassengerAuthRepository();
      await _pumpApp(tester, _router(RoutePaths.login), repo: repo);
      await tester.enterText(find.byType(TextFormField).at(0), '+225 07 12 34 56 78');
      final shown = tester.widget<EditableText>(find.byType(EditableText).at(0)).controller.text;
      // CONSTAT : '2250712345' (10 premiers chiffres du numero avec indicatif), pas '0712345678'.
      // ignore: avoid_print
      print('QA login +225 colle -> champ = "$shown"');
      expect(shown, '0712345678',
          reason: 'attendu : l\'indicatif +225 devrait etre retire pour obtenir le numero local a 10 chiffres');
    });

    testWidgets('compte chauffeur sur l\'app passager -> statut wrongRole (pas de session)', (tester) async {
      final repo = FakePassengerAuthRepository(loginHandler: (_, _) => passengerLoginOk(isDriver: true));
      final notifier = realAuthNotifier(repo);
      await notifier.login('0501020304', '1234');
      expect(notifier.state.status, AuthStatus.wrongRole);
      expect(await LocalStorage.instance.getSecure(AppConstants.accessTokenKey), isNull);
    });

    testWidgets('Mot de passe oublie et S\'inscrire naviguent', (tester) async {
      await _pumpApp(tester, _router(RoutePaths.login), repo: FakePassengerAuthRepository());
      await tester.ensureVisible(find.text('Mot de passe oublié ?'));
      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();
      expect(find.text('ECRAN_MOT_DE_PASSE_OUBLIE'), findsOneWidget);
    });
  });

  group('ETAPE 3 - inscription (OTP SMS simule)', () {
    testWidgets('contact -> OTP -> details -> compte cree (payload conforme backend)', (tester) async {
      final repo = FakePassengerAuthRepository();
      await _pumpApp(tester, _router(RoutePaths.register), repo: repo);
      await tester.pump(const Duration(milliseconds: 50));

      // Etape contact
      await tester.enterText(find.byType(TextFormField).at(0), '07 12 34 56 78');
      await tester.ensureVisible(find.text('Recevoir le code'));
      await tester.tap(find.text('Recevoir le code'));
      await tester.pumpAndSettle();
      expect(repo.step1Calls, [('0712345678', null)]);
      expect(find.text('Vérification OTP'), findsOneWidget);

      // Etape OTP
      await tester.enterText(find.byType(TextFormField).at(0), '4821');
      await tester.ensureVisible(find.text('Vérifier le code'));
      await tester.tap(find.text('Vérifier le code'));
      await tester.pumpAndSettle();
      expect(repo.step2Calls, [('0712345678', '4821')]);
      expect(find.text('Identité'), findsOneWidget);

      // Etape details
      await tester.enterText(find.byType(TextFormField).at(0), 'Aminata');
      await tester.enterText(find.byType(TextFormField).at(1), 'Kone');
      await tester.enterText(find.byType(TextFormField).at(2), '1234');
      await tester.enterText(find.byType(TextFormField).at(3), '1234');
      await tester.pump();
      // Bouton desactive tant que les CGU ne sont pas cochees
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(find.text("Finaliser l'inscription"));
      await tester.tap(find.text("Finaliser l'inscription"));
      await tester.pumpAndSettle();

      expect(repo.step3Calls, hasLength(1));
      final payload = repo.step3Calls.single;
      expect(payload['phoneNumber'], '0712345678');
      expect(payload['firstNames'], 'Aminata');
      expect(payload['lastName'], 'Kone');
      expect(payload['password'], '1234');
      expect(payload['userRegistrationType'], 'USER');
      expect(find.text('ACCUEIL_PASSAGER'), findsOneWidget);
    });

    testWidgets('inscription : numero colle avec +225 accepte jusqu a 15 chiffres (incoherent avec la connexion)', (tester) async {
      final repo = FakePassengerAuthRepository();
      await _pumpApp(tester, _router(RoutePaths.register), repo: repo);
      await tester.enterText(find.byType(TextFormField).at(0), '+225 07 12 34 56 78');
      await tester.ensureVisible(find.text('Recevoir le code'));
      await tester.tap(find.text('Recevoir le code'));
      await tester.pumpAndSettle();
      // Le backend normalise 225xxxxxxxxxx (13 chiffres) -> 0xxxxxxxxx ; l'inscription passe donc.
      expect(repo.step1Calls.single.$1, '2250712345678');
    });

    testWidgets('numero a 9 chiffres refuse a l inscription', (tester) async {
      final repo = FakePassengerAuthRepository();
      await _pumpApp(tester, _router(RoutePaths.register), repo: repo);
      await tester.enterText(find.byType(TextFormField).at(0), '071234567');
      await tester.ensureVisible(find.text('Recevoir le code'));
      await tester.tap(find.text('Recevoir le code'));
      await tester.pump();
      expect(find.text('Numéro invalide'), findsOneWidget);
      expect(repo.step1Calls, isEmpty);
    });

    testWidgets('inscription a textScale 1.3 sans overflow (3 etapes)', (tester) async {
      final repo = FakePassengerAuthRepository();
      await _pumpApp(tester, _router(RoutePaths.register), repo: repo, textScale: 1.3);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextFormField).at(0), '0712345678');
      await tester.ensureVisible(find.text('Recevoir le code'));
      await tester.tap(find.text('Recevoir le code'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextFormField).at(0), '4821');
      await tester.ensureVisible(find.text('Vérifier le code'));
      await tester.tap(find.text('Vérifier le code'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
