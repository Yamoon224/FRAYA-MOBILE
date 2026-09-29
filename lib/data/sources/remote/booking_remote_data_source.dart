library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/models/ride_share_link.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../sources/api_client.dart';
import 'booking_request_payload_builder.dart';
import 'booking_rate_response_helper.dart';
import 'booking_response_parser.dart';
import 'support_ticket_payload_builder.dart';

class BookingRemoteDataSource {
  BookingRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getRangePricing() async {
    try {
      final response = await _dio.get('/pricing/configs/range-pricing');
      final data = BookingResponseParser.asMap(response.data);

      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw ServerException(
        message: data['message']?.toString() ?? 'Unable to load ride ranges.',
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(message: 'Unable to load ride ranges: $error');
    }
  }

  Future<Map<String, dynamic>> calculatePrices(
    CalculateRidePricesParams params,
  ) async {
    try {
      logger.debug(
        'calculatePrices request: lat=${params.latDeparture} lng=${params.longDeparture} placeId=${params.arrivalPlaceId} arrivalLat=${params.arrivalLat} arrivalLng=${params.arrivalLong}',
      );
      final response = await _dio.post(
        '/rides/maps/estimate',
        data: {
          'currentLat': params.latDeparture,
          'currentLng': params.longDeparture,
          'destinationPlaceId': params.arrivalPlaceId,
          'stops': [
            for (final stop in params.stops)
              {'position': stop.position, 'placeId': stop.placeId},
          ],
          'promoCode': params.promoCode,
          'waitingSeconds': params.waitingSeconds,
        },
      );
      logger.debug('calculatePrices raw response: ${response.data}');
      return BookingResponseParser.asMap(response.data);
    } on DioException catch (error) {
      logger.error(
        'calculatePrices DioException: status=${error.response?.statusCode} data=${error.response?.data}',
        error,
      );
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(message: 'Unable to calculate ride price: $error');
    }
  }

  Future<Map<String, dynamic>> calculatePrice(CalculateRidePriceParams params) {
    return calculatePrices(
      CalculateRidePricesParams(
        latDeparture: params.latDeparture,
        longDeparture: params.longDeparture,
        arrivalPlaceId: params.arrivalPlaceId,
        arrivalLat: params.arrivalLat,
        arrivalLong: params.arrivalLong,
        stops: params.stops,
        promoCode: params.promoCode,
        waitingSeconds: params.waitingSeconds,
      ),
    );
  }

  Future<Map<String, dynamic>> requestRide(RequestRideParams params) async {
    try {
      final response = await _dio.post(
        '/rides/maps/request',
        data: BookingRequestPayloadBuilder.build(params),
      );
      return BookingResponseParser.asMap(response.data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(message: 'Unable to request ride: $error');
    }
  }

  Future<bool> cancelRide(String rideId, {String? reason}) async {
    try {
      final response = await _dio.post(
        '/rides/maps/$rideId/cancel',
        data: {
          'by': 'PASSENGER',
          'rideId': int.tryParse(rideId) ?? rideId,
          'reason': reason ?? 'Passenger cancellation',
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return false;
      }
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(message: 'Unable to cancel ride: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getUserRides(int userId) async {
    try {
      logger.debug(
        'getUserRides start: endpoint=/rides/maps userId=$userId tokenScoped=true',
      );
      final response = await _dio.get('/rides/maps');
      final unwrapped = BookingResponseParser.unwrapData(response.data);
      final rides = BookingResponseParser.extractRideList(response.data);
      if (unwrapped is! List && unwrapped is! Map) {
        logger.warning(
          'getUserRides unexpected payload type: ${unwrapped.runtimeType}',
        );
      }
      logger.debug(
        'getUserRides success: rides=${rides.length} payloadType=${unwrapped.runtimeType}',
      );
      return rides;
    } on DioException catch (error) {
      logger.warning(
        'getUserRides dio failure: status=${error.response?.statusCode} type=${error.type}',
      );
      if (error.response?.statusCode == 404) return const [];
      ApiClient.handleDioError(error);
    } catch (error) {
      logger.warning('getUserRides failure: $error');
      throw ServerException(message: 'Unable to load user rides: $error');
    }
  }

  Future<Map<String, dynamic>?> getActiveRide(int userId) async {
    try {
      final response = await _dio.get('/rides/maps/user/$userId/active');
      return BookingResponseParser.extractRideMap(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(message: 'Unable to load active ride: $error');
    }
  }

  Future<RideShareLink> createRideShareLink({
    required String rideId,
    int expiresIn = 60,
  }) async {
    try {
      final response = await _dio.post(
        '/rides/maps/$rideId/share',
        data: {'expiresIn': expiresIn},
      );
      final data = BookingResponseParser.asMap(response.data);
      final payload = data['data'];
      final share = payload is Map ? payload['share'] : null;
      if (data['success'] != true || share is! Map) {
        throw ServerException(
          message: data['message']?.toString() ??
              'Impossible de generer le lien de suivi.',
          statusCode: response.statusCode,
        );
      }

      final link = RideShareLink.fromMap(Map<String, dynamic>.from(share));
      if (link.url.isEmpty) {
        throw const ServerException(
          message: 'Impossible de generer le lien de suivi.',
        );
      }
      return link;
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: 'Unable to create ride share link: $error',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyDrivers() async {
    try {
      final response = await _dio.get(
        '/rides/maps/drivers/nearby',
        queryParameters: {'onlineOnly': true},
      );
      final data = BookingResponseParser.asMap(response.data);
      final list = data['data'] ?? data['drivers'] ?? [];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(message: 'Unable to load nearby drivers: $error');
    }
  }

  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  }) async {
    try {
      final response = await _dio.post(
        '/rides/maps/$rideId/rate',
        data: {
          'rating': rating,
          ...?comment == null ? null : {'comment': comment},
          ...?tip == null ? null : {'tip': tip},
        },
      );
      final statusCode = response.statusCode;
      if (BookingRateResponseHelper.isSuccessfulStatus(statusCode)) {
        BookingRateResponseHelper.logInfo(
          'rateRide dataSource success: rideId=$rideId statusCode=$statusCode outcome=submitted',
        );
        return RateRideOutcome.submitted;
      }
      BookingRateResponseHelper.logWarning(
        'rateRide dataSource failure: rideId=$rideId statusCode=$statusCode outcome=failure',
      );
      throw ServerException(
        message: 'Unable to rate ride.',
        statusCode: statusCode,
      );
    } on DioException catch (error) {
      final message = BookingRateResponseHelper.extractDioMessage(error);
      final statusCode = error.response?.statusCode;
      if (BookingRateResponseHelper.isAlreadySubmittedConflict(
        statusCode: statusCode,
        message: message,
        responseData: error.response?.data,
      )) {
        BookingRateResponseHelper.logInfo(
          'rateRide dataSource success: rideId=$rideId statusCode=$statusCode outcome=already_submitted',
        );
        return RateRideOutcome.alreadySubmitted;
      }
      BookingRateResponseHelper.logWarning(
        'rateRide dataSource failure: rideId=$rideId statusCode=$statusCode outcome=failure',
      );
      ApiClient.handleDioError(error);
    } catch (error) {
      BookingRateResponseHelper.logWarning(
        'rateRide dataSource failure: rideId=$rideId statusCode=null outcome=failure',
      );
      throw ServerException(message: 'Unable to rate ride: $error');
    }
  }

  Future<bool> triggerSos({
    required String rideId,
    required int userId,
    required double lat,
    required double lng,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/alerts/create',
        data: {
          'courseId': int.tryParse(rideId) ?? rideId,
          'passagerId': userId,
          'userId': userId,
          'lat': lat,
          'lng': lng,
          'sendPolice': false,
          'sendContacts': false,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (error) {
      _handleActionDioError(error, action: _BookingAction.sos);
    } catch (error) {
      throw ServerException(message: 'Unable to create SOS alert: $error');
    }
  }

  Future<bool> createSupportTicket({
    required String rideId,
    required int userId,
    required String category,
    String? description,
  }) async {
    final payload = SupportTicketPayloadBuilder.fromReportProblem(
      category: category,
      description: description,
    );
    try {
      final response = await _postSupportTicket(
        rideId: rideId,
        userId: userId,
        draft: payload,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (error) {
      if (_shouldRetrySupportType(error, attemptedType: payload.type)) {
        final fallbackDraft = SupportTicketPayloadBuilder.fromReportProblem(
          category: category,
          description: description,
          overrideType: SupportTicketPayloadBuilder.fallbackType,
        );
        try {
          final retryResponse = await _postSupportTicket(
            rideId: rideId,
            userId: userId,
            draft: fallbackDraft,
          );
          return retryResponse.statusCode == 200 ||
              retryResponse.statusCode == 201;
        } on DioException catch (retryError) {
          _handleActionDioError(retryError, action: _BookingAction.support);
        }
      }
      _handleActionDioError(error, action: _BookingAction.support);
    } catch (error) {
      throw ServerException(message: 'Unable to report problem: $error');
    }
  }

  Future<Response<dynamic>> _postSupportTicket({
    required String rideId,
    required int userId,
    required SupportTicketDraft draft,
  }) {
    return _dio.post(
      '/support/create',
      data: {
        'userId': userId,
        'courseId': int.tryParse(rideId) ?? rideId,
        'type': draft.type,
        'description': draft.description,
        'priorite': draft.priority,
      },
    );
  }

  Never _handleActionDioError(
    DioException error, {
    required _BookingAction action,
  }) {
    try {
      ApiClient.handleDioError(error);
    } on ValidationException catch (validation) {
      throw ValidationException(
        message: _normalizeActionMessage(
          message: validation.message,
          statusCode: error.response?.statusCode,
          action: action,
          fields: validation.fields,
        ),
        fields: validation.fields,
      );
    } on ServerException catch (server) {
      throw ServerException(
        message: _normalizeActionMessage(
          message: server.message,
          statusCode: server.statusCode,
          action: action,
          fields: _extractFields(error.response?.data),
        ),
        statusCode: server.statusCode,
      );
    }
  }

  String _normalizeActionMessage({
    required String message,
    required _BookingAction action,
    required int? statusCode,
    Map<String, String>? fields,
  }) {
    final normalizedFields = fields ?? const <String, String>{};
    final lowerMessage = message.toLowerCase();
    final lowerFieldKeys = normalizedFields.keys
        .map((key) => key.toLowerCase())
        .toList(growable: false);
    final lowerFieldValues = normalizedFields.values
        .map((value) => value.toLowerCase())
        .toList(growable: false);

    final hasRequiredFieldIssue =
        lowerMessage.contains('required') ||
        lowerFieldValues.any((value) => value.contains('required'));
    if (hasRequiredFieldIssue) {
      return 'Un champ obligatoire est manquant.';
    }

    final mentionsUser =
        lowerMessage.contains('user') ||
        lowerMessage.contains('utilisateur') ||
        lowerFieldKeys.any((key) => key.contains('user'));
    final mentionsCourse =
        lowerMessage.contains('course') ||
        lowerMessage.contains('cours') ||
        lowerFieldKeys.any((key) => key.contains('course'));
    final mentionsNotFound =
        statusCode == 404 ||
        lowerMessage.contains('not found') ||
        lowerMessage.contains('non trouvé') ||
        lowerMessage.contains('introuvable');
    if (mentionsNotFound && mentionsUser && mentionsCourse) {
      return 'Utilisateur ou course introuvable.';
    }
    if (mentionsNotFound && mentionsCourse) {
      return 'Course introuvable.';
    }
    if (mentionsNotFound && mentionsUser) {
      return 'Utilisateur introuvable.';
    }

    if (action == _BookingAction.support &&
        (_containsTypeField(lowerFieldKeys) ||
            lowerMessage.contains('ticket') ||
            lowerMessage.contains('support') ||
            lowerMessage.contains('priority'))) {
      return 'Ticket support invalide.';
    }

    return message;
  }

  bool _shouldRetrySupportType(
    DioException error, {
    required String attemptedType,
  }) {
    if (attemptedType == SupportTicketPayloadBuilder.fallbackType) {
      return false;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != 400 && statusCode != 422) {
      return false;
    }

    final message = _extractMessage(error.response?.data).toLowerCase();
    final fields = _extractFields(error.response?.data);
    final lowerFieldKeys = fields.keys
        .map((key) => key.toLowerCase())
        .toList(growable: false);
    final lowerFieldValues = fields.values
        .map((value) => value.toLowerCase())
        .toList(growable: false);

    return _containsTypeField(lowerFieldKeys) ||
        message.contains('type') ||
        lowerFieldValues.any((value) => value.contains('type'));
  }

  bool _containsTypeField(List<String> fields) {
    return fields.any((field) => field.contains('type'));
  }

  Map<String, String> _extractFields(dynamic data) {
    final errors = data is Map<String, dynamic> ? data['errors'] : null;
    if (errors is Map) {
      return errors.map(
        (key, value) => MapEntry(key.toString(), _stringValue(value)),
      );
    }
    if (errors is List) {
      final fields = <String, String>{};
      for (final error in errors) {
        if (error is Map && error['field'] != null) {
          fields[error['field'].toString()] = _stringValue(error['message']);
        }
      }
      return fields;
    }
    return const {};
  }

  String _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
    }
    return '';
  }

  String _stringValue(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    return value?.toString() ?? '';
  }
}

enum _BookingAction { sos, support }
