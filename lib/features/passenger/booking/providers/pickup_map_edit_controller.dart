import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/places_models.dart';
import '../../../../core/services/address_formatter_service.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';

class MapAddressEditState {
  const MapAddressEditState({
    this.isEditing = false,
    this.isDragging = false,
    this.isResolvingAddress = false,
    this.draftLatLng,
    this.draftAddress,
    this.draftName,
    this.draftPlaceId,
    this.errorText,
    this.shouldOpenTextSearch = false,
  });

  final bool isEditing;
  final bool isDragging;
  final bool isResolvingAddress;
  final LatLng? draftLatLng;
  final String? draftAddress;
  final String? draftName;
  final String? draftPlaceId;
  final String? errorText;
  final bool shouldOpenTextSearch;

  static const _sentinel = Object();

  MapAddressEditState copyWith({
    bool? isEditing,
    bool? isDragging,
    bool? isResolvingAddress,
    Object? draftLatLng = _sentinel,
    Object? draftAddress = _sentinel,
    Object? draftName = _sentinel,
    Object? draftPlaceId = _sentinel,
    Object? errorText = _sentinel,
    bool? shouldOpenTextSearch,
  }) {
    return MapAddressEditState(
      isEditing: isEditing ?? this.isEditing,
      isDragging: isDragging ?? this.isDragging,
      isResolvingAddress: isResolvingAddress ?? this.isResolvingAddress,
      draftLatLng: draftLatLng == _sentinel
          ? this.draftLatLng
          : draftLatLng as LatLng?,
      draftAddress: draftAddress == _sentinel
          ? this.draftAddress
          : draftAddress as String?,
      draftName: draftName == _sentinel ? this.draftName : draftName as String?,
      draftPlaceId: draftPlaceId == _sentinel
          ? this.draftPlaceId
          : draftPlaceId as String?,
      errorText: errorText == _sentinel ? this.errorText : errorText as String?,
      shouldOpenTextSearch: shouldOpenTextSearch ?? this.shouldOpenTextSearch,
    );
  }
}

// Backward-compat alias
typedef PickupMapEditState = MapAddressEditState;

final mapAddressEditControllerProvider = StateNotifierProvider.autoDispose
    .family<MapAddressEditController, MapAddressEditState, SearchType>(
      (ref, target) => MapAddressEditController(ref, target),
    );

// Backward-compat alias
final pickupMapEditControllerProvider = mapAddressEditControllerProvider(
  SearchType.pickup,
);

class MapAddressEditController extends StateNotifier<MapAddressEditState> {
  MapAddressEditController(this._ref, this._target)
    : super(const MapAddressEditState());

  final Ref _ref;
  final SearchType _target;
  int _requestId = 0;
  static const _fallbackLabel = 'Point sélectionné sur la carte';
  static const _addressFormatter = AddressFormatterService();

  void enterEditMode(LatLng initialLatLng) {
    state = state.copyWith(
      isEditing: true,
      isDragging: false,
      isResolvingAddress: true,
      draftLatLng: initialLatLng,
      errorText: null,
      shouldOpenTextSearch: false,
    );
    _requestId++;
    unawaited(_resolveAddress(initialLatLng, _requestId, publish: false));
  }

  void handleCameraMoveStarted() {
    if (!state.isEditing) return;
    state = state.copyWith(
      isDragging: true,
      isResolvingAddress: false,
      errorText: null,
    );
  }

  void handleCameraIdle(LatLng center) {
    if (!state.isEditing) return;
    state = state.copyWith(
      isDragging: false,
      isResolvingAddress: true,
      draftLatLng: center,
      errorText: null,
    );
    _requestId++;
    unawaited(_resolveAddress(center, _requestId, publish: false));
  }

  void handleMarkerDragStarted() {
    if (!state.isEditing) return;
    state = state.copyWith(
      isDragging: true,
      isResolvingAddress: false,
      errorText: null,
    );
  }

  void handleMarkerDragEnd(LatLng position) {
    if (!state.isEditing) return;
    state = state.copyWith(
      isDragging: false,
      isResolvingAddress: true,
      draftLatLng: position,
      errorText: null,
    );
    _requestId++;
    unawaited(_resolveAddress(position, _requestId, publish: true));
  }

  Future<void> confirmSelection() async {
    final center = state.draftLatLng;
    if (center == null) return;

    _publishPlace(center);
    cancelEditing();
  }

  void cancelEditing() {
    state = const MapAddressEditState();
  }

  void requestTextSearchFallback() {
    if (!state.isEditing) return;
    state = state.copyWith(shouldOpenTextSearch: true);
  }

  void consumeTextSearchFallback() {
    if (!state.shouldOpenTextSearch) return;
    state = state.copyWith(shouldOpenTextSearch: false);
  }

  Future<void> _resolveAddress(
    LatLng center,
    int requestId, {
    required bool publish,
  }) async {
    try {
      final geocoding = _ref.read(geocodingServiceProvider);
      final result = await geocoding.reverseGeocode(
        center.latitude,
        center.longitude,
      );
      if (!mounted || requestId != _requestId) return;

      final quartier = _trimToNull(result['quartier']);
      final commune = _trimToNull(result['commune']);
      final formatted = _trimToNull(result['formatted']);
      final placeId = _trimToNull(result['placeId']);
      final name = quartier ?? commune ?? _fallbackLabel;
      final address = formatted ?? name;

      state = state.copyWith(
        isResolvingAddress: false,
        draftLatLng: center,
        draftName: name,
        draftAddress: address,
        draftPlaceId: placeId,
        errorText: null,
      );
      if (publish) {
        _publishPlace(center);
      }
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      final fallbackName = _trimToNull(state.draftName) ?? _fallbackLabel;
      state = state.copyWith(
        isResolvingAddress: false,
        draftLatLng: center,
        draftName: fallbackName,
        draftAddress: _trimToNull(state.draftAddress) ?? fallbackName,
        errorText: 'Impossible de recuperer cette adresse pour le moment.',
      );
      if (publish) {
        _publishPlace(center);
      }
    }
  }

  void _publishPlace(LatLng center) {
    final rawName = _trimToNull(state.draftName) ?? _fallbackLabel;
    final normalizedAddress = _addressFormatter.normalize(
      state.draftAddress ?? '',
    );
    final address = _trimToNull(normalizedAddress) ?? rawName;
    final resolvedPlaceId = _trimToNull(state.draftPlaceId) ??
        'manual_map_${DateTime.now().millisecondsSinceEpoch}';
    final place = PlaceDetails(
      placeId: resolvedPlaceId,
      name: rawName,
      address: address,
      latitude: center.latitude,
      longitude: center.longitude,
    );
    if (_target == SearchType.pickup) {
      _ref.read(selectedPickupProvider.notifier).setPlace(place);
    } else {
      _ref.read(selectedDestinationProvider.notifier).setPlace(place);
    }
  }

  String? _trimToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

// Backward-compat alias
typedef PickupMapEditController = MapAddressEditController;
