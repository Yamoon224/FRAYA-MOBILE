library;

import 'dart:async';

enum ApiAvailabilityState { reachable, checking, unreachable }

class ApiAvailabilityGuard {
  ApiAvailabilityGuard._();

  static final ApiAvailabilityGuard instance = ApiAvailabilityGuard._();
  static const int _failureThreshold = 2;

  final _controller = StreamController<ApiAvailabilityState>.broadcast();
  ApiAvailabilityState _state = ApiAvailabilityState.reachable;
  int _consecutiveFailures = 0;

  ApiAvailabilityState get state => _state;
  Stream<ApiAvailabilityState> get changes => _controller.stream;

  bool shouldBlockMethod(String method) {
    if (_state != ApiAvailabilityState.unreachable) return false;
    return switch (method.toUpperCase()) {
      'POST' || 'PUT' || 'PATCH' || 'DELETE' => true,
      _ => false,
    };
  }

  void setState(ApiAvailabilityState state) {
    if (state == ApiAvailabilityState.reachable) {
      _consecutiveFailures = 0;
    } else if (state == ApiAvailabilityState.unreachable) {
      _consecutiveFailures = _failureThreshold;
    }
    _setState(state);
  }

  void recordReachable() {
    setState(ApiAvailabilityState.reachable);
  }

  void recordConnectivityFailure() {
    _consecutiveFailures++;
    _setState(
      _consecutiveFailures >= _failureThreshold
          ? ApiAvailabilityState.unreachable
          : ApiAvailabilityState.checking,
    );
  }

  void reset() {
    setState(ApiAvailabilityState.reachable);
  }

  void _setState(ApiAvailabilityState state) {
    if (_state == state) return;
    _state = state;
    _controller.add(state);
  }
}
