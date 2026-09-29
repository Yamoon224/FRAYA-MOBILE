library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/places_models.dart';
import '../../../../core/utils/constants.dart';
import '../../../../data/sources/local_storage.dart';
import 'payment_method_provider.dart';

final passengerBookingSessionStoreProvider =
    Provider<PassengerBookingSessionStore>((ref) {
      return PassengerBookingSessionStore(LocalStorage.instance);
    });

class PassengerBookingSession {
  const PassengerBookingSession({
    required this.pickup,
    required this.destination,
    required this.createdAt,
    this.rideId,
    this.categoryId,
    this.paymentMethod,
    this.routeIndex = 0,
  });

  final PlaceDetails? pickup;
  final PlaceDetails? destination;
  final DateTime createdAt;
  final String? rideId;
  final String? categoryId;
  final PaymentMethod? paymentMethod;
  final int routeIndex;

  Map<String, dynamic> toJson() => {
    'pickup': pickup?.toLocalJson(),
    'destination': destination?.toLocalJson(),
    'createdAt': createdAt.millisecondsSinceEpoch,
    'rideId': rideId,
    'categoryId': categoryId,
    'paymentMethod': paymentMethod?.name,
    'routeIndex': routeIndex,
  };

  factory PassengerBookingSession.fromJson(Map<String, dynamic> json) {
    return PassengerBookingSession(
      pickup: _placeFromJson(json['pickup']),
      destination: _placeFromJson(json['destination']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      rideId: json['rideId'] as String?,
      categoryId: json['categoryId'] as String?,
      paymentMethod: _paymentMethodFromName(json['paymentMethod'] as String?),
      routeIndex: (json['routeIndex'] as num?)?.toInt() ?? 0,
    );
  }

  static PlaceDetails? _placeFromJson(Object? value) {
    if (value is! Map) return null;
    return PlaceDetails.fromLocalJson(Map<String, dynamic>.from(value));
  }

  static PaymentMethod? _paymentMethodFromName(String? name) {
    if (name == null) return null;
    for (final item in PaymentMethod.values) {
      if (item.name == name) return item;
    }
    return null;
  }
}

class PassengerBookingSessionStore {
  const PassengerBookingSessionStore(this._storage);

  final LocalStorage _storage;

  PassengerBookingSession? read() {
    if (!_storage.isInitialized) return null;
    final raw = _storage.getString(AppConstants.passengerBookingSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return PassengerBookingSession.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      clear();
      return null;
    }
  }

  Future<bool> save(PassengerBookingSession session) {
    if (!_storage.isInitialized) return Future<bool>.value(false);
    return _storage.setString(
      AppConstants.passengerBookingSessionKey,
      jsonEncode(session.toJson()),
    );
  }

  Future<bool> clear() {
    if (!_storage.isInitialized) return Future<bool>.value(false);
    return _storage.remove(AppConstants.passengerBookingSessionKey);
  }
}
