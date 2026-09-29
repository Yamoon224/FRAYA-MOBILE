import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/realtime/realtime_events.dart';
import '../../../../core/realtime/socket_health_state.dart';
import '../../../../data/sources/remote/booking_remote_data_source.dart';
import '../../../../shared/providers/realtime_providers.dart';

part 'nearby_drivers_provider.g.dart';

final nearbyDriversDataSourceProvider = Provider<BookingRemoteDataSource>(
  (ref) => BookingRemoteDataSource(),
);

class NearbyDriver {
  final String id;
  final LatLng location;
  final double bearing;
  final String? vehicleColorRaw;

  NearbyDriver({
    required this.id,
    required this.location,
    required this.bearing,
    this.vehicleColorRaw,
  });

  NearbyDriver copyWith({
    LatLng? location,
    double? bearing,
    String? vehicleColorRaw,
  }) {
    return NearbyDriver(
      id: id,
      location: location ?? this.location,
      bearing: bearing ?? this.bearing,
      vehicleColorRaw: vehicleColorRaw ?? this.vehicleColorRaw,
    );
  }
}

@riverpod
class NearbyDrivers extends _$NearbyDrivers {
  Timer? _fallbackTimer;
  StreamSubscription<SocketHealthState>? _healthSub;
  StreamSubscription<NearbyDriverMovingEvent>? _socketSub;
  late BookingRemoteDataSource _dataSource;
  final _lastSeenById = <String, DateTime>{};
  static const _driverTtl = Duration(seconds: 20);
  static const _smoothingFactor = 0.35;

  @override
  List<NearbyDriver> build() {
    ref.onDispose(_dispose);
    _dataSource = ref.read(nearbyDriversDataSourceProvider);

    final realtimeService = ref.read(realtimeServiceProvider);
    _socketSub = realtimeService.nearbyDriverMovingStream.listen(
      _handleSocketEvent,
    );
    _healthSub = realtimeService.healthStream.listen(_handleHealthUpdate);

    _startFallbackPolling();
    return [];
  }

  void _handleHealthUpdate(SocketHealthState health) {
    if (health == SocketHealthState.connected ||
        health == SocketHealthState.reconnecting) {
      _stopFallbackPolling();
      return;
    }
    _startFallbackPolling();
  }

  void _startFallbackPolling() {
    _fallbackTimer?.cancel();
    _fetchDrivers();
    _fallbackTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _fetchDrivers(),
    );
  }

  void _stopFallbackPolling() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  Future<void> refreshNow({bool clearStale = true}) async {
    if (clearStale) {
      _pruneStaleDrivers();
    }
    await _fetchDrivers();
  }

  void _dispose() {
    _fallbackTimer?.cancel();
    _healthSub?.cancel();
    _socketSub?.cancel();
  }

  void _handleSocketEvent(NearbyDriverMovingEvent event) {
    final location = LatLng(event.latitude, event.longitude);
    _applyDriverUpdate(
      id: event.driverId,
      newLocation: location,
      suggestedBearing: event.bearing,
      vehicleColorRaw: event.vehicleColorRaw,
    );
    _pruneStaleDrivers();
  }

  Future<void> _fetchDrivers() async {
    try {
      final raw = await _dataSource.getNearbyDrivers();
      for (final d in raw) {
        final id = d['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final lat = _toDouble(d['latitude'] ?? d['lat']);
        final lng = _toDouble(d['longitude'] ?? d['lng'] ?? d['long']);
        if (lat == null || lng == null) continue;
        final newLocation = LatLng(lat, lng);
        _applyDriverUpdate(
          id: id,
          newLocation: newLocation,
          vehicleColorRaw: _firstString([
            d['vehicleColor'],
            d['carColor'],
            d['color'],
          ]),
        );
      }
      _pruneStaleDrivers();
    } catch (_) {
      // Keep existing state on error
    }
  }

  void _applyDriverUpdate({
    required String id,
    required LatLng newLocation,
    double? suggestedBearing,
    String? vehicleColorRaw,
  }) {
    final prev = state.firstWhere(
      (nd) => nd.id == id,
      orElse: () => NearbyDriver(id: id, location: newLocation, bearing: 0),
    );
    final smoothed = _smoothLocation(prev.location, newLocation);
    final bearing =
        suggestedBearing ?? _computeBearing(prev.location, smoothed);
    final resolvedVehicleColorRaw = vehicleColorRaw ?? prev.vehicleColorRaw;
    _lastSeenById[id] = DateTime.now();

    final next = [
      for (final driver in state)
        if (driver.id != id) driver,
      NearbyDriver(
        id: id,
        location: smoothed,
        bearing: bearing,
        vehicleColorRaw: resolvedVehicleColorRaw,
      ),
    ];
    state = next;
  }

  void _pruneStaleDrivers() {
    final cutoff = DateTime.now().subtract(_driverTtl);
    _lastSeenById.removeWhere((_, seenAt) => seenAt.isBefore(cutoff));
    state = state
        .where((driver) => _lastSeenById.containsKey(driver.id))
        .toList();
  }

  LatLng _smoothLocation(LatLng from, LatLng to) {
    final lat =
        from.latitude + (to.latitude - from.latitude) * _smoothingFactor;
    final lng =
        from.longitude + (to.longitude - from.longitude) * _smoothingFactor;
    return LatLng(lat, lng);
  }

  double _computeBearing(LatLng from, LatLng to) {
    if (from.latitude == to.latitude && from.longitude == to.longitude) {
      return 0;
    }
    final fromLat = _toRadians(from.latitude);
    final toLat = _toRadians(to.latitude);
    final dLng = _toRadians(to.longitude - from.longitude);
    final y = sin(dLng) * cos(toLat);
    final x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}
