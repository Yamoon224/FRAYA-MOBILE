// Aides communes du parcours QA passager (Samsung Galaxy A15, Android 14).
// Tout est faux/inerte : aucun reseau, aucun GPS, aucune socket, aucun push.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/core/utils/logger.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/models/ride_share_link.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ecran Samsung Galaxy A15 : 1080x2340 px, dpr 2.625 (411x891 dp).
void useGalaxyA15(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// Enveloppe MaterialApp avec echelle de texte (1.0 par defaut, 1.3 = police agrandie One UI).
Widget withTextScale(Widget child, {double scale = 1.0}) {
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(411, 891),
      devicePixelRatio: 2.625,
      textScaler: TextScaler.linear(scale),
    ),
    child: child,
  );
}

Future<void> initQaEnvironment({Map<String, String>? secure}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppConfig.instance.init(flavor: AppFlavor.dev);
  AppLogger.instance.init();
  FlutterSecureStorage.setMockInitialValues(secure ?? <String, String>{});
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await LocalStorage.instance.init();
  await initializeDateFormatting('fr_FR');
}

/// Depot d'auth faux : enveloppes identiques a celles du backend NestJS
/// (`{success, data:{access_token, refresh_token, user}}`).
class FakePassengerAuthRepository extends PassengerAuthRepository {
  FakePassengerAuthRepository({this.loginHandler});

  final Map<String, dynamic> Function(String phone, String password)?
  loginHandler;
  final List<(String, String)> loginCalls = [];
  final List<(String, String?)> step1Calls = [];
  final List<(String, String)> step2Calls = [];
  final List<Map<String, dynamic>> step3Calls = [];

  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    loginCalls.add((phoneNumber, password));
    return loginHandler?.call(phoneNumber, password) ?? passengerLoginOk();
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) async {
    step1Calls.add((phoneNumber, email));
  }

  @override
  Future<void> registerStep2(String phoneNumber, String verificationCode) async {
    step2Calls.add((phoneNumber, verificationCode));
  }

  @override
  Future<Map<String, dynamic>> registerStep3(Map<String, dynamic> userData) async {
    step3Calls.add(userData);
    return passengerLoginOk();
  }
}

Map<String, dynamic> passengerLoginOk({bool isDriver = false}) => {
  'success': true,
  'data': {
    'access_token': 'jwt-aminata',
    'refresh_token': 'refresh-aminata',
    'user': {
      'id': 7,
      'firstNames': 'Aminata',
      'lastName': 'Kone',
      'phoneNumber': '0712345678',
      'isDriver': isDriver,
    },
  },
};

PassengerAuthNotifier realAuthNotifier(FakePassengerAuthRepository repo) {
  return PassengerAuthNotifier(
    loginUsecase: LoginPassengerUsecase(repo),
    registerStep1Usecase: RegisterStep1Usecase(repo),
    registerStep2Usecase: RegisterStep2Usecase(repo),
    registerStep3Usecase: RegisterStep3Usecase(repo),
    logoutUsecase: LogoutPassengerUsecase(),
  );
}

/// Notifier d'auth dont l'etat initial est impose (utilisateur deja connecte).
class PresetAuthNotifier extends PassengerAuthNotifier {
  PresetAuthNotifier(AuthState preset)
    : super(
        loginUsecase: LoginPassengerUsecase(FakePassengerAuthRepository()),
        registerStep1Usecase: RegisterStep1Usecase(FakePassengerAuthRepository()),
        registerStep2Usecase: RegisterStep2Usecase(FakePassengerAuthRepository()),
        registerStep3Usecase: RegisterStep3Usecase(FakePassengerAuthRepository()),
        logoutUsecase: LogoutPassengerUsecase(),
      ) {
    state = preset;
  }
}

/// Depot de courses faux, parametrable. Les methodes non utilisees levent
/// une erreur explicite (pas de reseau cache).
class QaBookingRepository implements BookingRepository {
  QaBookingRepository({
    this.categories = const [],
    this.prices = const {},
    this.rides = const [],
    this.activeRideHandler,
    this.requestRideHandler,
  });

  final List<RideCategory> categories;
  final Map<String, RidePriceEstimate> prices;
  List<Map<String, dynamic>> rides;
  final ActiveRide? Function(int userId, String? rideId)? activeRideHandler;
  final Future<String> Function(RequestRideParams params)? requestRideHandler;

  final List<RequestRideParams> requests = [];
  final List<String> cancelled = [];
  final List<({String rideId, int rating, String? comment})> ratings = [];

  @override
  Future<List<RideCategory>> getRideCategories() async => categories;

  @override
  Future<Map<String, RidePriceEstimate>> calculateRidePrices(
    CalculateRidePricesParams params,
  ) async => prices;

  @override
  Future<int?> calculateRidePrice(CalculateRidePriceParams params) async => null;

  @override
  Future<String> requestRide(RequestRideParams params) async {
    requests.add(params);
    return requestRideHandler != null
        ? requestRideHandler!(params)
        : 'ride_qa_1';
  }

  @override
  Future<bool> cancelRide(String rideId, {String? reason}) async {
    cancelled.add(rideId);
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getUserRides(int userId) async => rides;

  @override
  Future<ActiveRide?> getActiveRide(int userId, {String? rideId}) async =>
      activeRideHandler?.call(userId, rideId);

  @override
  Future<RideShareLink> createRideShareLink({
    required String rideId,
    int expiresIn = 60,
  }) async => throw UnimplementedError('createRideShareLink');

  @override
  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  }) async {
    ratings.add((rideId: rideId, rating: rating, comment: comment));
    return RateRideOutcome.submitted;
  }

  @override
  Future<bool> triggerSos({
    required String rideId,
    required int userId,
    required double lat,
    required double lng,
    String? notes,
  }) async => true;

  @override
  Future<bool> createSupportTicket({
    required String rideId,
    required int userId,
    required String category,
    String? description,
  }) async => true;
}

/// Course telle que renvoyee par GET /rides (statusRace du backend NestJS).
Map<String, dynamic> backendRideMap({
  required String statusRace,
  String id = 'ride_qa_1',
  int finalPrice = 2500,
  String departure = 'Angre 8e tranche, Cocody',
  String arrival = 'Universite FHB, Cocody',
  String? driverPhone = '0501020304',
}) {
  return {
    'id': id,
    'statusRace': statusRace,
    'requestedRange': 'MAGIC',
    'departureAddress': departure,
    'arrivalAddress': arrival,
    'latDeparture': 5.4,
    'longDeparture': -3.99,
    'arrivalLat': 5.34,
    'arrivalLong': -4.02,
    'estimatedPrice': 2500,
    'finalPrice': finalPrice,
    'estimatedDistance': '6.4 km',
    'estimatedDuration': '18 min',
    'createdAt': '2026-10-27T08:00:00.000Z',
    if (statusRace != 'REQUESTED' && statusRace != 'SEARCHING_DRIVER')
      'driver': {
        'firstNames': 'Yao',
        'lastName': 'Brou',
        'phoneNumber': driverPhone,
        'rating': 4.7,
      },
    if (statusRace != 'REQUESTED' && statusRace != 'SEARCHING_DRIVER')
      'vehicle': {
        'brand': 'Toyota',
        'model': 'Yaris',
        'licensePlate': '1234 AB 01',
        'color': 'Blanc',
      },
  };
}


/// Charge Roboto (fournie avec le SDK Flutter) a la place de la police Ahem des tests
/// (Ahem = carres de 1 em de large, qui exagerent enormement les debordements).
/// Roboto est proche des metriques reelles de One UI / Inter (Inter est ~4 % plus large).
/// Les familles 'Inter_*' (google_fonts) sont aliasees sur Roboto.
Future<bool> loadRealisticFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/Users/LENOVO/Flutter/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());
  try {
    final regular = read('roboto-regular.ttf');
    final medium = read('roboto-medium.ttf');
    final bold = read('roboto-bold.ttf');
    final families = <String, Future<ByteData>>{
      'Roboto': regular,
      'Inter_regular': regular,
      'Inter_300': regular,
      'Inter_500': medium,
      'Inter_600': bold,
      'Inter_700': bold,
      'Inter_800': bold,
    };
    for (final e in families.entries) {
      final loader = FontLoader(e.key)..addFont(e.value);
      await loader.load();
    }
    final loaderBold = FontLoader('Roboto')..addFont(medium)..addFont(bold);
    await loaderBold.load();
    return true;
  } catch (_) {
    return false;
  }
}
