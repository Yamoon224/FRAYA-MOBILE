import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/places_provider.dart';
import 'booking_flow_provider.dart';
import 'ride_categories_provider.dart';

part 'ride_price_auto_refresh_provider.g.dart';

const ridePriceAutoRefreshInterval = Duration(seconds: 10);

final ridePriceAutoRefreshIntervalProvider = Provider<Duration>(
  (_) => ridePriceAutoRefreshInterval,
);

final ridePriceAutoRefreshLifecycleStateProvider = Provider<AppLifecycleState?>(
  (_) => WidgetsBinding.instance.lifecycleState,
);

@riverpod
class RidePriceAutoRefresh extends _$RidePriceAutoRefresh {
  Timer? _timer;

  @override
  void build() {
    ref.onDispose(_stop);
    _stop();

    final flowState = ref.watch(bookingFlowProvider);
    if (flowState == BookingFlowState.routePreview) {
      _start();
    }
  }

  Future<void> refreshNow() => _refreshPrice();

  void _start() {
    final interval = ref.read(ridePriceAutoRefreshIntervalProvider);
    _timer = Timer.periodic(interval, (_) => unawaited(_refreshPrice()));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _refreshPrice() async {
    if (ref.read(bookingFlowProvider) != BookingFlowState.routePreview) return;
    if (ref.read(ridePriceAutoRefreshLifecycleStateProvider) !=
        AppLifecycleState.resumed) {
      return;
    }

    final destination = ref.read(selectedDestinationProvider);
    if (destination == null || !destination.hasValidCoordinates) return;
    if (!_isBackendPricingPlaceId(destination.placeId)) return;

    if (ref.read(rideCategoriesProvider).isLoading) return;

    final flag = ref.read(ridePriceAutoRefreshInProgressProvider.notifier);
    flag.state = true;
    try {
      ref.invalidate(rideCategoriesProvider);
      await ref.read(rideCategoriesProvider.future);
    } finally {
      flag.state = false;
    }
  }
}

bool _isBackendPricingPlaceId(String placeId) {
  final value = placeId.trim();
  if (value.isEmpty) return false;
  return !value.startsWith('manual_') &&
      !value.startsWith('manual_map_') &&
      !value.startsWith('landmark_');
}
