library;

import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../utils/logger.dart';
import 'realtime_events.dart';
import 'realtime_service.dart';
import 'socket_health_state.dart';

class SocketIoRealtimeService implements RealtimeService {
  SocketIoRealtimeService();

  static const int _maxReconnectionAttempts = 8;
  static const int _reconnectionDelayMs = 1000;
  static const int _maxReconnectionDelayMs = 30000;
  static const _rideCancellationEvents = [
    'ride_cancelled',
    'ride_cancelled_driver',
    'ride_cancelled_passenger',
  ];

  final _nearbyController =
      StreamController<NearbyDriverMovingEvent>.broadcast();
  final _rideAcceptedController =
      StreamController<RideAcceptedEvent>.broadcast();
  final _positionController =
      StreamController<RidePositionUpdateEvent>.broadcast();
  final _driverRideStatusController =
      StreamController<DriverRideStatusRealtimeEvent>.broadcast();
  final _passengerLifecycleController =
      StreamController<DriverRideStatusRealtimeEvent>.broadcast();
  final _newRideOfferController =
      StreamController<NewRideOfferEvent>.broadcast();
  final _forceLogoutController = StreamController<void>.broadcast();
  final _healthController = StreamController<SocketHealthState>.broadcast();

  io.Socket? _publicSocket;
  io.Socket? _ridesSocket;
  Timer? _degradedTimer;
  Timer? _offlineTimer;
  SocketHealthState _health = SocketHealthState.offline;
  bool _disposed = false;

  @override
  Stream<NearbyDriverMovingEvent> get nearbyDriverMovingStream =>
      _nearbyController.stream;
  @override
  Stream<RideAcceptedEvent> get rideAcceptedStream =>
      _rideAcceptedController.stream;
  @override
  Stream<RidePositionUpdateEvent> get ridePositionUpdateStream =>
      _positionController.stream;
  @override
  Stream<DriverRideStatusRealtimeEvent> get driverRideStatusStream =>
      _driverRideStatusController.stream;
  @override
  Stream<DriverRideStatusRealtimeEvent> get passengerRideLifecycleStream =>
      _passengerLifecycleController.stream;
  @override
  Stream<NewRideOfferEvent> get newRideOfferStream =>
      _newRideOfferController.stream;
  @override
  Stream<void> get forceLogoutStream => _forceLogoutController.stream;
  @override
  Stream<SocketHealthState> get healthStream => _healthController.stream;

  @override
  Future<void> connectPassenger({
    required String token,
    required int userId,
  }) async {
    await _connect(token: token, userId: userId);
  }

  @override
  Future<void> connectDriver({
    required String token,
    required int userId,
  }) async {
    await _connect(token: token, userId: userId);
  }

  Future<void> _connect({required String token, required int userId}) async {
    await disconnect();
    if (_disposed) return;
    final baseUrl = _socketBaseUrl();
    _publicSocket = _buildPublicSocket(baseUrl, token, userId);
    _ridesSocket = _buildRidesSocket(baseUrl, token, userId);
    _publicSocket?.connect();
    _ridesSocket?.connect();
  }

  dynamic _buildSocketOptions(String token, Map<String, dynamic> query) =>
      io.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectionAttempts)
          .setReconnectionDelay(_reconnectionDelayMs)
          .setReconnectionDelayMax(_maxReconnectionDelayMs)
          .setTimeout(20000)
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setQuery(query)
          .build();

  void _attachBaseHandlers(io.Socket socket, String label) {
    socket.onConnect((_) {
      _markConnected();
      logger.info('SocketIO connected on namespace "$label"');
    });
    socket.onDisconnect((_) => _markReconnecting());
    socket.onConnectError((_) => _markReconnecting());
    socket.onError((_) => _markReconnecting());
    socket.on('reconnect_attempt', (_) => _markReconnecting());
    socket.on('reconnect_error', (_) => _markReconnecting());
    socket.on('reconnect_failed', (_) => _markOffline());
  }

  void _tryAdd<T>(StreamController<T> ctrl, T? event) {
    if (event != null && !ctrl.isClosed) ctrl.add(event);
  }

  io.Socket _buildPublicSocket(String baseUrl, String token, int userId) {
    final socket = io.io(
      '$baseUrl/',
      _buildSocketOptions(token, {'userId': '$userId'}),
    );
    _attachBaseHandlers(socket, '/');
    socket.on(
      'nearbyDriverMoving',
      (p) => _tryAdd(_nearbyController, NearbyDriverMovingEvent.tryParse(p)),
    );
    socket.on(
      'positionUpdate',
      (p) => _tryAdd(_positionController, RidePositionUpdateEvent.tryParse(p)),
    );
    socket.on(
      'new_ride_available',
      (p) => _tryAdd(_newRideOfferController, NewRideOfferEvent.tryParse(p)),
    );
    for (final e in ['ride_started_driver', 'ride_completed_driver']) {
      socket.on(
        e,
        (p) => _tryAdd(
          _driverRideStatusController,
          DriverRideStatusRealtimeEvent.tryParse(p),
        ),
      );
    }
    _attachRideCancellationHandlers(socket);
    for (final e in ['ride_started', 'driver_arrived', 'ride_completed']) {
      socket.on(
        e,
        (p) => _tryAdd(
          _passengerLifecycleController,
          DriverRideStatusRealtimeEvent.tryParse(p),
        ),
      );
    }
    return socket;
  }

  io.Socket _buildRidesSocket(String baseUrl, String token, int userId) {
    final socket = io.io(
      '$baseUrl/rides',
      _buildSocketOptions(token, {'userId': '$userId'}),
    );
    _attachBaseHandlers(socket, '/rides');
    socket.on(
      'ride_accepted',
      (p) => _tryAdd(_rideAcceptedController, RideAcceptedEvent.tryParse(p)),
    );
    socket.on(
      'ride_notification',
      (p) => _tryAdd(_newRideOfferController, NewRideOfferEvent.tryParse(p)),
    );
    _attachRideCancellationHandlers(socket);
    socket.on('force_logout', (_) {
      if (!_forceLogoutController.isClosed) _forceLogoutController.add(null);
    });
    return socket;
  }

  @override
  void joinRide(int rideId) {
    if (rideId <= 0) return;
    _publicSocket?.emit('joinRide', {'rideId': rideId});
    _ridesSocket?.emit('joinRide', {'rideId': rideId});
  }

  void _attachRideCancellationHandlers(io.Socket socket) {
    for (final eventName in _rideCancellationEvents) {
      socket.on(eventName, (payload) {
        final event = DriverRideStatusRealtimeEvent.tryParse(
          payload,
          fallbackStatus: 'CANCELLED',
        );
        if (event == null) return;
        _tryAdd(_driverRideStatusController, event);
        _tryAdd(_passengerLifecycleController, event);
      });
    }
  }

  @override
  Future<void> disconnect() async {
    _cancelHealthTimers();
    _disconnectSocket(_publicSocket);
    _disconnectSocket(_ridesSocket);
    _publicSocket = null;
    _ridesSocket = null;
    _setHealth(SocketHealthState.offline);
  }

  void _disconnectSocket(io.Socket? socket) {
    if (socket == null) return;
    try {
      socket.clearListeners();
      socket.disconnect();
      socket.dispose();
    } catch (_) {}
  }

  void _markConnected() {
    _cancelHealthTimers();
    _setHealth(SocketHealthState.connected);
  }

  void _markReconnecting() {
    if (_disposed) return;
    _setHealth(SocketHealthState.reconnecting);
    _cancelHealthTimers();
    _degradedTimer = Timer(const Duration(seconds: 8), _markDegraded);
    _offlineTimer = Timer(const Duration(seconds: 20), _markOffline);
  }

  void _markDegraded() {
    if (_disposed) return;
    _setHealth(SocketHealthState.degraded);
  }

  void _markOffline() {
    if (_disposed) return;
    _setHealth(SocketHealthState.offline);
  }

  void _setHealth(SocketHealthState next) {
    if (_disposed) return;
    if (_health == next) return;
    _health = next;
    _healthController.add(next);
  }

  void _cancelHealthTimers() {
    _degradedTimer?.cancel();
    _degradedTimer = null;
    _offlineTimer?.cancel();
    _offlineTimer = null;
  }

  String _socketBaseUrl() {
    final apiUri = Uri.parse(AppConfig.instance.baseUrl);
    final hasDefaultPort =
        (apiUri.scheme == 'http' && apiUri.port == 80) ||
        (apiUri.scheme == 'https' && apiUri.port == 443);
    final port = hasDefaultPort ? '' : ':${apiUri.port}';
    return '${apiUri.scheme}://${apiUri.host}$port';
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    _nearbyController.close();
    _rideAcceptedController.close();
    _positionController.close();
    _driverRideStatusController.close();
    _passengerLifecycleController.close();
    _newRideOfferController.close();
    _forceLogoutController.close();
    _healthController.close();
  }
}
