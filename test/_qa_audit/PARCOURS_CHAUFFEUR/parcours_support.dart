// Aides du parcours chauffeur (QA) : téléphone Samsung Galaxy A25 5G + faux serveur NestJS.
//
// Le faux serveur se branche sur Dio via un HttpClientAdapter : les VRAIS dépôts, sources distantes et
// modèles de l'application sont donc exercés, avec des réponses calquées sur le backend
// (enveloppe successResponse/errorResponse, statuts statusRace, champs RideResource).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'dart:ui' show Size;

import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter_test/flutter_test.dart';

/// Galaxy A25 5G : 1080x2340 px, dpr 2.625 -> 411 x 891 dp.
void usePhone(WidgetTester tester, {double textScale = 1.0}) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

const phoneScales = <double>[1.0, 1.3];

/// Faux backend Fraya. Reproduit les règles de rides.service.ts :
/// accept (SEARCHING_DRIVER -> DRIVER_ASSIGNED), arrived (-> WAITING_FOR_PASSENGER),
/// start (-> IN_PROGRESS), complete (-> COMPLETED, prix recalculé côté serveur, commission débitée).
class FakeFrayaBackend implements HttpClientAdapter {
  FakeFrayaBackend();

  final List<RequestOptions> requests = [];
  final List<Object?> bodies = [];

  /// Course unique du scénario (JSON façon RideResource).
  Map<String, dynamic>? ride;

  /// Historique complet côté base (pour GET /rides/maps paginé comme nestjs-paginate).
  List<Map<String, dynamic>> allRides = [];

  bool online = false;
  bool farFromPickup = false;
  int driverUserId = 14;
  double walletBalance = 4000;
  int serverFinalPrice = 3200;
  double commissionRate = 0.15;

  static const int _defaultPaginateLimit = 20;

  Iterable<RequestOptions> callsTo(String method, Pattern path) => requests
      .where((r) => r.method == method && r.path.contains(path));

  static Map<String, dynamic> rideJson({
    required int id,
    String status = 'SEARCHING_DRIVER',
    int? driverUserId,
    int? vehicleId,
    num estimatedPrice = 3200,
    num? finalPrice,
    String passengerFirst = 'Koffi',
    String passengerLast = 'Yao',
    String phone = '0707070707',
    String pickup = 'Carrefour Texaco, Bingerville',
    String dest = 'Plateau, Abidjan',
    String paymentMode = 'CASH',
    String? pickupArrivedAt,
    String? departureDate,
    String? createdAt,
  }) {
    return {
      'id': id,
      'requestedRange': 'MAGIC',
      'departureAddress': pickup,
      'latDeparture': 5.3556,
      'longDeparture': -3.8887,
      'arrivalAddress': dest,
      'arrivalLat': 5.3200,
      'arrivalLong': -4.0160,
      'estimatedDistance': 14.2,
      'estimatedDuration': 32,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'paymentMode': paymentMode,
      'statusRace': status,
      'pickupArrivedAt': pickupArrivedAt,
      'departureDate': departureDate,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'sidUser': {
        'id': 77,
        'firstNames': passengerFirst,
        'lastName': passengerLast,
        'phoneNumber': phone,
        'rating': 4.7,
        'coursesCount': 12,
      },
      if (driverUserId != null && vehicleId != null)
        'vehicle': {
          'id': vehicleId,
          'range': 'MAGIC',
          'licensePlate': '1234 AB 01',
          'sidUserId': driverUserId,
        },
    };
  }

  Map<String, dynamic> _ok(dynamic data, [String msg = 'Operation successful']) => {
    'success': true,
    'message': msg,
    'statusCode': 200,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'data': data,
  };

  Map<String, dynamic> _ko(String msg) => {
    'success': false,
    'statusCode': 404,
    'message': msg,
  };

  ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    bodies.add(options.data);
    final path = options.path;
    final m = options.method;

    if (m == 'PUT' && path == '/sid-users/me/online') {
      online = (options.data as Map)['isOnline'] == true;
      return _json(_ok(null));
    }
    if (m == 'POST' && path == '/sid-users/me/heartbeat') {
      return _json(_ok(null));
    }
    if (m == 'GET' && path == '/rides/maps/available') {
      final r = ride;
      final list = (r != null && r['statusRace'] == 'SEARCHING_DRIVER' && online)
          ? [r]
          : <Map<String, dynamic>>[];
      return _json(_ok(list, 'Courses disponibles récupérées'));
    }
    final driverActive = RegExp(r'^/rides/maps/driver/(\d+)/active$').firstMatch(path);
    if (m == 'GET' && driverActive != null) {
      const active = {
        'DRIVER_ASSIGNED',
        'DRIVER_EN_ROUTE',
        'WAITING_FOR_PASSENGER',
        'IN_PROGRESS',
      };
      final r = ride;
      final owner = (r?['vehicle'] as Map?)?['sidUserId'];
      if (r == null || !active.contains(r['statusRace']) || owner != int.parse(driverActive.group(1)!)) {
        return _json(_ok(null, 'Aucune course active trouvée pour ce conducteur'));
      }
      return _json(_ok(r, 'Course active récupérée avec succès'));
    }
    if (m == 'GET' && path == '/rides/maps') {
      final limit = int.tryParse('${options.queryParameters['limit'] ?? ''}') ??
          _defaultPaginateLimit;
      final page = int.tryParse('${options.queryParameters['page'] ?? ''}') ?? 1;
      final sorted = [...allRides]..sort(
        (a, b) => (b['id'] as int).compareTo(a['id'] as int),
      );
      final slice = sorted.skip((page - 1) * limit).take(limit).toList();
      return _json({
        'success': true,
        'statusCode': 200,
        'data': slice,
        'meta': {
          'itemsPerPage': limit,
          'totalItems': sorted.length,
          'currentPage': page,
          'totalPages': (sorted.length / limit).ceil(),
        },
      });
    }

    final action = RegExp(r'^/rides/maps/(\d+)/(accept|arrived|start|complete|cancel)$')
        .firstMatch(path);
    if (m == 'POST' && action != null) {
      final r = ride;
      final verb = action.group(2)!;
      if (r == null || '${r['id']}' != action.group(1)) {
        return _json(_ko('Course non trouvée'));
      }
      final status = r['statusRace'];
      switch (verb) {
        case 'accept':
          if (status != 'SEARCHING_DRIVER') {
            return _json({'message': 'Ride already accepted by another driver'}, 409);
          }
          final vehicleId = (options.data as Map)['vehicleId'];
          r['statusRace'] = 'DRIVER_ASSIGNED';
          r['vehicle'] = {
            'id': vehicleId,
            'range': 'MAGIC',
            'licensePlate': '1234 AB 01',
            'sidUserId': driverUserId,
          };
          r['dateAcceptance'] = DateTime.now().toIso8601String();
        case 'arrived':
          if (farFromPickup) {
            // BadRequestException NestJS : HTTP 400 avec { statusCode, message, error }.
            return _json({
              'statusCode': 400,
              'message':
                  'Vous êtes trop loin du point de départ pour marquer votre arrivée (Distance: 350m).',
              'error': 'Bad Request',
            }, 400);
          }
          if (status != 'DRIVER_ASSIGNED') {
            return _json({
              'statusCode': 400,
              'message': 'Impossible de marquer l\'arrivée (statut actuel : $status)',
              'error': 'Bad Request',
            }, 400);
          }
          r['statusRace'] = 'WAITING_FOR_PASSENGER';
          r['pickupArrivedAt'] = DateTime.now().toIso8601String();
        case 'start':
          if (status != 'WAITING_FOR_PASSENGER') {
            return _json(_ko('La course ne peut démarrer qu\'après l\'arrivée.'));
          }
          r['statusRace'] = 'IN_PROGRESS';
          r['departureDate'] = DateTime.now().toIso8601String();
        case 'complete':
          if (status != 'IN_PROGRESS') {
            return _json(_ko('Seules les courses en cours peuvent être terminées.'));
          }
          r['statusRace'] = 'COMPLETED';
          r['finalPrice'] = serverFinalPrice;
          final commission = (serverFinalPrice * commissionRate).round();
          r['commissionPrice'] = commission;
          r['amountReceived'] = serverFinalPrice - commission;
          r['dateArrival'] = DateTime.now().toIso8601String();
          walletBalance -= commission;
          allRides = [
            ...allRides.where((e) => e['id'] != r['id']),
            Map<String, dynamic>.from(r),
          ];
        case 'cancel':
          r['statusRace'] = 'CANCELLED_DRIVER';
      }
      return _json(_ok(r));
    }
    return _json({'message': 'route inconnue $m $path'}, 404);
  }
}

Dio fakeDio(FakeFrayaBackend backend) =>
    Dio(BaseOptions(baseUrl: 'https://fake.test/api'))..httpClientAdapter = backend;

/// Par défaut flutter_test affiche tout en police Ahem (1 em par lettre, ~1,8x plus large que la vraie police) :
/// les débordements mesurés seraient faux. On enregistre Roboto (livrée avec le SDK Flutter, largeur proche
/// d'Inter) sous les noms de famille utilisés par google_fonts (Inter, Inter_400 ... Inter_800).
Future<void> loadRealisticFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/Users/LENOVO/Flutter/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> bytes(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());
  const families = <String, String>{
    'Roboto': 'roboto-regular.ttf',
    'Inter': 'roboto-regular.ttf',
    'Inter_300': 'roboto-light.ttf',
    'Inter_400': 'roboto-regular.ttf',
    'Inter_regular': 'roboto-regular.ttf',
    'Inter_100': 'roboto-light.ttf',
    'Inter_200': 'roboto-light.ttf',
    'Inter_500': 'roboto-medium.ttf',
    'Inter_600': 'roboto-bold.ttf',
    'Inter_700': 'roboto-bold.ttf',
    'Inter_800': 'roboto-black.ttf',
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key)..addFont(bytes(e.value));
    await loader.load();
  }
}
