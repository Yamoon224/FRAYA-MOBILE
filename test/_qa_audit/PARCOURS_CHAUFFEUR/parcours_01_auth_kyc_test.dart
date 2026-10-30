// PARCOURS CHAUFFEUR - étapes 1 à 4 : présentation/splash, connexion, inscription, KYC + véhicule,
// et routage selon le statut du compte. Vrai notifier d'authentification + faux dépôt (enveloppes backend).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/router/driver_router.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';
import 'package:fraya_mobile/domain/repositories/auth_register_draft_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_auth_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_kyc_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_vehicle_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/login_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/logout_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/refresh_driver_profile_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_usecase.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_local_session.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_register_flow_provider.dart';
import 'package:fraya_mobile/features/driver/auth/screens/driver_login_screen.dart';
import 'package:fraya_mobile/features/driver/auth/screens/driver_register_screen.dart';
import 'package:fraya_mobile/features/driver/kyc/providers/driver_kyc_dependencies.dart';
import 'package:fraya_mobile/features/driver/onboarding/providers/driver_onboarding_draft_dependencies.dart';
import 'package:fraya_mobile/features/driver/vehicle/providers/driver_vehicle_dependencies.dart';
import 'package:fraya_mobile/features/driver/vehicle/screens/driver_registration_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/auth_register_draft_provider.dart';
import 'package:fraya_mobile/shared/providers/auth_register_flow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/driver/vehicle/providers/driver_vehicle_provider_test_support.dart';
import '../../support/driver_document_preparation_test_double.dart';
import '../../support/driver_test_doubles.dart';
import 'parcours_support.dart';

// ---------------------------------------------------------------- doubles

class _AuthRepo implements DriverAuthRepository {
  Map<String, dynamic> loginResponse = {
    'success': true,
    'statusCode': 200,
    'data': {
      'access_token': 'tok-driver',
      'refresh_token': 'ref-driver',
      'user': {
        'id': 14,
        'firstNames': 'Adama',
        'lastName': 'Traoré',
        'phone': '0707123456',
        'isDriver': true,
        'isUser': false,
        'kycStatus': 'APPROVED',
        'vehicleStatus': 'APPROVED',
        'vehicleId': 7,
        'driverId': 14,
      },
    },
  };
  Object? loginError;
  final List<List<String>> logins = [];
  final List<String> step1 = [];
  final List<List<String>> step2 = [];
  final List<Map<String, dynamic>> registrations = [];

  @override
  Future<Map<String, dynamic>> fetchProfile() async => {'data': loginResponse['data']['user']};

  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    logins.add([phoneNumber, password]);
    if (loginError != null) throw loginError!;
    return loginResponse;
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    registrations.add(userData);
    return loginResponse;
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) async =>
      step1.add(phoneNumber);

  @override
  Future<void> registerStep2(String phoneNumber, String verificationCode) async =>
      step2.add([phoneNumber, verificationCode]);
}

class _MemorySession extends DriverAuthLocalSession {
  @override
  Future<void> persist(String token, Map<String, dynamic> userData) async {}
  @override
  Future<Map<String, dynamic>?> restore() async => null;
}

class _DraftRepo implements AuthRegisterDraftRepository {
  final Map<AuthRegisterRole, AuthRegisterDraft> drafts = {};
  @override
  Future<void> clearDraft(AuthRegisterRole role) async => drafts.remove(role);
  @override
  Future<AuthRegisterDraft?> readDraft(AuthRegisterRole role) async => drafts[role];
  @override
  Future<void> saveDraft(AuthRegisterDraft draft) async => drafts[draft.role] = draft;
}

DriverAuthNotifier _notifier(_AuthRepo repo) => DriverAuthNotifier(
  loginUseCase: LoginDriverUseCase(repo),
  registerUseCase: RegisterDriverUseCase(repo),
  registerStep1UseCase: RegisterDriverStep1UseCase(repo),
  registerStep2UseCase: RegisterDriverStep2UseCase(repo),
  logoutUseCase: LogoutDriverUseCase(),
  refreshProfileUseCase: RefreshDriverProfileUseCase(repo),
  localSession: _MemorySession(),
  autoRestore: false,
);

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

List<String> _drain(WidgetTester t) {
  final out = <String>[];
  Object? e;
  while ((e = t.takeException()) != null) {
    out.add(e.toString().split(RegExp(r'[\r\n]+')).first);
  }
  return out;
}

String _fieldText(WidgetTester t, int index) =>
    t.widget<EditableText>(find.byType(EditableText).at(index)).controller.text;

Future<DriverAuthNotifier> _pumpLogin(
  WidgetTester tester,
  _AuthRepo repo, {
  String? initialPhone,
}) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  await LocalStorage.instance.init();
  final notifier = _notifier(repo);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [driverAuthProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(home: DriverLoginScreen(initialPhone: initialPhone)),
    ),
  );
  await _settle(tester, 2);
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealisticFonts);

  // ------------------------------------------------------------ étape 1
  group('S1 splash / présentation (routage initial)', () {
    test('démarrage : le splash reste affiché tant que la session se restaure', () {
      expect(
        resolveDriverRedirect(
          authState: AuthState(status: AuthStatus.idle),
          currentPath: RoutePaths.splash,
        ),
        isNull,
      );
    });
    test('non connecté : splash -> connexion ; pas d\'écran de présentation dans le flavor chauffeur', () {
      expect(
        resolveDriverRedirect(
          authState: AuthState(status: AuthStatus.unauthenticated),
          currentPath: RoutePaths.splash,
        ),
        RoutePaths.login,
      );
      // Aucune route "onboarding"/"présentation" n'existe dans RoutePaths (revue de driver_router.dart).
      final allPaths = <String>[
        RoutePaths.splash,
        RoutePaths.login,
        RoutePaths.register,
        RoutePaths.driverHome,
        RoutePaths.driverKyc,
        RoutePaths.driverVehicle,
        RoutePaths.driverVehiclePending,
      ];
      expect(allPaths.any((p) => p.contains('onboarding') || p.contains('intro')), isFalse);
    });
  });

  // ------------------------------------------------------------ routage selon statut du compte
  group('S3/S4 routage selon le statut du compte (KYC + véhicule)', () {
    String? redirect(Map<String, dynamic> userData, String path) => resolveDriverRedirect(
      authState: AuthState(status: AuthStatus.authenticated, userData: userData),
      currentPath: path,
    );

    test('compte neuf (NOT_SUBMITTED) -> page unique d\'inscription véhicule+documents', () {
      expect(
        redirect({'driverId': 14, 'kycStatus': 'NOT_SUBMITTED'}, RoutePaths.driverHome),
        RoutePaths.driverVehicle,
      );
    });
    test('dossier envoyé, en attente de validation -> écran d\'attente', () {
      expect(
        redirect({
          'driverId': 14,
          'kycStatus': 'PENDING_VALIDATION',
          'vehicleStatus': 'PENDING_VALIDATION',
          'vehicleId': 7,
        }, RoutePaths.driverHome),
        RoutePaths.driverVehiclePending,
      );
    });
    test('KYC refusé -> écran de correction KYC', () {
      expect(
        redirect({'driverId': 14, 'kycStatus': 'REJECTED'}, RoutePaths.driverHome),
        RoutePaths.driverKyc,
      );
    });
    test('véhicule refusé -> écran véhicule', () {
      expect(
        redirect({
          'driverId': 14,
          'kycStatus': 'APPROVED',
          'vehicleStatus': 'REJECTED',
          'vehicleId': 7,
        }, RoutePaths.driverHome),
        RoutePaths.driverVehicle,
      );
    });
    test('compte validé -> accueil, y compris depuis connexion/splash', () {
      const ok = {
        'driverId': 14,
        'kycStatus': 'APPROVED',
        'vehicleStatus': 'APPROVED',
        'vehicleId': 7,
      };
      expect(redirect(ok, RoutePaths.login), RoutePaths.driverHome);
      expect(redirect(ok, RoutePaths.splash), RoutePaths.driverHome);
      expect(redirect(ok, RoutePaths.driverHome), isNull);
      expect(redirect(ok, RoutePaths.driverVehiclePending), RoutePaths.driverHome);
    });
    test('mauvais rôle (compte passager) -> écran "mauvais compte"', () {
      expect(
        resolveDriverRedirect(
          authState: AuthState(status: AuthStatus.wrongRole),
          currentPath: RoutePaths.driverHome,
        ),
        RoutePaths.driverWrongAccount,
      );
    });
  });

  // ------------------------------------------------------------ étape 2 connexion
  for (final scale in phoneScales) {
    group('S2 connexion - Galaxy A25 5G textScale $scale', () {
      testWidgets('numéro 10 chiffres + code 4 chiffres -> connexion réussie', (tester) async {
        usePhone(tester, textScale: scale);
        final repo = _AuthRepo();
        final notifier = await _pumpLogin(tester, repo);
        expect(find.text('Connectez-vous en tant que chauffeur'), findsOneWidget);
        expect(_drain(tester), isEmpty, reason: 'pas d\'overflow à l\'ouverture');

        await tester.enterText(find.byType(EditableText).at(0), '0707123456');
        await tester.enterText(find.byType(EditableText).at(1), '1234');
        await tester.ensureVisible(find.text('Se connecter'));
        await tester.tap(find.text('Se connecter'));
        await _settle(tester);

        expect(repo.logins, [
          ['0707123456', '1234'],
        ]);
        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.userData?['kycStatus'], 'APPROVED');
        expect(_drain(tester), isEmpty);
      });

      testWidgets('validation : numéro trop court et mot de passe vide', (tester) async {
        usePhone(tester, textScale: scale);
        final repo = _AuthRepo();
        await _pumpLogin(tester, repo);
        await tester.enterText(find.byType(EditableText).at(0), '07071');
        await tester.ensureVisible(find.text('Se connecter'));
        await tester.tap(find.text('Se connecter'));
        await _settle(tester, 3);
        expect(find.text('Numéro invalide'), findsOneWidget);
        expect(find.text('Veuillez entrer votre mot de passe'), findsOneWidget);
        expect(repo.logins, isEmpty);
      });
    });
  }

  testWidgets('S2 identifiants refusés par le serveur : message visible, pas de session', (tester) async {
    usePhone(tester);
    final repo = _AuthRepo()..loginError = const AuthException(message: 'Identifiants incorrects');
    final notifier = await _pumpLogin(tester, repo);
    await tester.enterText(find.byType(EditableText).at(0), '0707123456');
    await tester.enterText(find.byType(EditableText).at(1), '9999');
    await tester.ensureVisible(find.text('Se connecter'));
    await tester.tap(find.text('Se connecter'));
    await _settle(tester, 4);
    expect(notifier.state.status, AuthStatus.error);
    expect(find.text('Identifiants incorrects'), findsWidgets);
    await tester.pump(const Duration(seconds: 12));
  });

  testWidgets('S2 numéro collé avec +225 ou 225 : le champ ne doit pas être tronqué en un mauvais numéro', (
    tester,
  ) async {
    usePhone(tester);
    final repo = _AuthRepo();
    await _pumpLogin(tester, repo);
    await tester.enterText(find.byType(EditableText).at(0), '+225 07 07 12 34 56');
    final text = _fieldText(tester, 0);
    // digitsOnly puis limite à 10 : "2250707123" (10 premiers chiffres) -> numéro faux, accepté par le validateur.
    // ignore: avoid_print
    print('S2-paste +225 -> champ = "$text" (${text.length} chiffres)');
    expect(
      text == '0707123456' || text == '2250707123456',
      isTrue,
      reason: 'le numéro collé "+225 07 07 12 34 56" est devenu "$text"',
    );
  });

  // ------------------------------------------------------------ étape 3 inscription
  for (final scale in phoneScales) {
    testWidgets('S3 inscription complète : téléphone -> OTP 4 chiffres -> identité -> création (textScale $scale)', (
      tester,
    ) async {
      usePhone(tester, textScale: scale);
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await LocalStorage.instance.init();
      final repo = _AuthRepo();
      final notifier = _notifier(repo);
      final drafts = _DraftRepo();
      final container = ProviderContainer(
        overrides: [
          driverAuthProvider.overrideWith((ref) => notifier),
          authRegisterDraftRepositoryProvider.overrideWithValue(drafts),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DriverRegisterScreen()),
        ),
      );
      await _settle(tester, 3);
      expect(find.text('Rejoignez nos chauffeurs partenaires'), findsOneWidget);

      // contact
      await tester.enterText(find.byType(EditableText).at(0), '0707123456');
      await tester.ensureVisible(find.text('Recevoir le code'));
      await tester.tap(find.text('Recevoir le code'));
      await _settle(tester, 4);
      expect(repo.step1, ['0707123456']);
      expect(find.text('Vérification OTP'), findsOneWidget);

      // otp
      await tester.enterText(find.byType(EditableText).first, '1234');
      await tester.ensureVisible(find.text('Vérifier le code'));
      await tester.tap(find.text('Vérifier le code'));
      await _settle(tester, 4);
      expect(repo.step2, [
        ['0707123456', '1234'],
      ]);
      expect(find.text("Finaliser l'inscription"), findsOneWidget);

      // détails : prénoms, nom, date (sélecteur), code 4 chiffres x2, CGU
      await tester.enterText(find.byType(EditableText).at(0), 'Adama');
      await tester.enterText(find.byType(EditableText).at(1), 'Traoré');
      await tester.tap(find.byType(EditableText).at(2));
      await _settle(tester, 3);
      await tester.tap(find.text('OK'));
      await _settle(tester, 3);
      await tester.enterText(find.byType(EditableText).at(3), '1234');
      await tester.enterText(find.byType(EditableText).at(4), '1234');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(find.text("Finaliser l'inscription"));
      await tester.tap(find.text("Finaliser l'inscription"));
      await _settle(tester, 5);

      expect(repo.registrations, hasLength(1));
      final payload = repo.registrations.single;
      expect(payload['phoneNumber'], '0707123456');
      expect(payload['firstNames'], 'Adama');
      expect(payload['lastName'], 'Traoré');
      expect(payload['password'], '1234');
      expect(payload['userRegistrationType'], 'DRIVER');
      expect(payload['dateOfBirth'], '1990-01-01');
      expect(notifier.state.status, AuthStatus.authenticated);
      container.read(driverRegisterFlowProvider);
      await tester.pump(const Duration(seconds: 40));
    });
  }

  testWidgets('S3 la case CGU est obligatoire : sans elle le bouton reste inactif', (tester) async {
    usePhone(tester);
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
    final repo = _AuthRepo();
    final notifier = _notifier(repo);
    final flow = AuthRegisterFlowController(
      role: AuthRegisterRole.driver,
      userRegistrationType: 'DRIVER',
      draftRepository: _DraftRepo(),
      sendOtpAction: (p, {email}) async {},
      verifyOtpAction: (p, c) async {},
      completeRegistrationAction: (_) async {},
      isAuthenticated: () => false,
    );
    flow.updateDraftFields(
      phoneNumber: '0707123456',
      email: '',
      firstNames: 'Adama',
      lastName: 'Traoré',
      genre: null,
    );
    await flow.sendOtp();
    await flow.verifyOtp('1234');
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => notifier),
        driverRegisterFlowProvider.overrideWith((ref) => flow),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DriverRegisterScreen()),
      ),
    );
    await _settle(tester, 3);
    await tester.enterText(find.byType(EditableText).at(3), '1234');
    await tester.enterText(find.byType(EditableText).at(4), '1234');
    await tester.pump();
    await tester.ensureVisible(find.text("Finaliser l'inscription"));
    await tester.tap(find.text("Finaliser l'inscription"), warnIfMissed: false);
    await _settle(tester, 3);
    expect(repo.registrations, isEmpty);
    await tester.pump(const Duration(seconds: 40));
  });

  testWidgets('S3 numéro collé +225 à l inscription : doit être envoyé au format local (comme à la connexion)', (
    tester,
  ) async {
    usePhone(tester);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LocalStorage.instance.init();
    final repo = _AuthRepo();
    final notifier = _notifier(repo);
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith((ref) => notifier),
        authRegisterDraftRepositoryProvider.overrideWithValue(_DraftRepo()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DriverRegisterScreen()),
      ),
    );
    await _settle(tester, 3);
    await tester.enterText(find.byType(EditableText).at(0), '+225 07 07 12 34 56');
    await tester.ensureVisible(find.text('Recevoir le code'));
    await tester.tap(find.text('Recevoir le code'));
    await _settle(tester, 4);
    // ignore: avoid_print
    print('S3-paste +225 -> registerStep1 reçoit ${repo.step1}');
    expect(repo.step1, ['0707123456'],
        reason: 'la connexion convertit +225… en 10 chiffres ; l inscription envoie ${repo.step1}');
    await tester.pump(const Duration(seconds: 40));
  });

  // ------------------------------------------------------------ étape 4 KYC + véhicule
  for (final scale in phoneScales) {
    testWidgets('S4 inscription véhicule + documents (page unique) - textScale $scale', (tester) async {
      usePhone(tester, textScale: scale);
      SharedPreferences.setMockInitialValues({});
      await LocalStorage.instance.init();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            driverAuthProvider.overrideWith(
              (ref) => FakeDriverAuthNotifier(
                AuthState(
                  status: AuthStatus.authenticated,
                  userData: const {'driverId': 14, 'kycStatus': 'NOT_SUBMITTED'},
                ),
              ),
            ),
            driverOnboardingDraftRepositoryProvider.overrideWithValue(
              InMemoryDriverOnboardingDraftRepository(),
            ),
            driverDocumentPreparationServiceProvider.overrideWithValue(
              PassthroughDriverDocumentPreparationService(),
            ),
            driverKycRepositoryProvider.overrideWithValue(_NoopKyc()),
            driverVehicleRepositoryProvider.overrideWithValue(_NoopVehicle()),
          ],
          child: const MaterialApp(home: DriverRegistrationScreen()),
        ),
      );
      await _settle(tester, 4);
      expect(find.text('Envoyer mon dossier'), findsOneWidget);
      // Documents chauffeur demandés : permis recto/verso. Pas de pièce d'identité (CNI) dans la liste.
      expect(find.textContaining('Permis'), findsWidgets);
      expect(find.textContaining('CNI'), findsNothing);
      expect(find.textContaining('identité'), findsNothing);
      expect(_drain(tester), isEmpty, reason: 'pas d\'overflow sur l\'écran d\'inscription véhicule');
    });
  }
}

class _NoopKyc implements DriverKycRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _NoopVehicle implements DriverVehicleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
