library;

import 'dart:async';

/// Notifie [PassengerHomeScreen] d'ouvrir [DestinationSearchSheet].
///
/// Pattern identique à [AuthSessionNotifier] : singleton + stream broadcast.
class HomeNavigationNotifier {
  HomeNavigationNotifier._();

  static final HomeNavigationNotifier instance = HomeNavigationNotifier._();

  final _openSearchController = StreamController<void>.broadcast();
  final _resetSearchStateController = StreamController<void>.broadcast();
  final _openVehicleSelectionController = StreamController<void>.broadcast();
  bool _resetSearchStateOnHomePending = false;
  bool _openDestinationSearchOnHomePending = false;

  Stream<void> get openSearchEvents => _openSearchController.stream;
  Stream<void> get resetSearchStateEvents => _resetSearchStateController.stream;
  Stream<void> get openVehicleSelectionEvents =>
      _openVehicleSelectionController.stream;
  bool get hasResetSearchStateOnHomePending => _resetSearchStateOnHomePending;
  bool consumeResetSearchStateOnHomePending() {
    final shouldReset = _resetSearchStateOnHomePending;
    _resetSearchStateOnHomePending = false;
    return shouldReset;
  }

  bool get hasOpenDestinationSearchOnHomePending =>
      _openDestinationSearchOnHomePending;
  bool consumeOpenDestinationSearchOnHomePending() {
    final shouldOpen = _openDestinationSearchOnHomePending;
    _openDestinationSearchOnHomePending = false;
    return shouldOpen;
  }

  void requestOpenDestinationSearch() => _openSearchController.add(null);
  void requestResetSearchState() {
    _resetSearchStateOnHomePending = true;
    _resetSearchStateController.add(null);
  }

  void requestOpenVehicleSelection() =>
      _openVehicleSelectionController.add(null);
  void requestOpenDestinationSearchOnHome() {
    _openDestinationSearchOnHomePending = true;
  }
}
