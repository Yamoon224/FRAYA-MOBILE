/// Ecran de previsualisation de l'itineraire + selection de categorie.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/address_search_sheet_launcher.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_flow_listeners.dart';
import '../widgets/route_map_section.dart';
import '../widgets/route_preview_bottom_sheet.dart';
import '../widgets/route_preview_map_stack.dart';
import 'map_address_picker_screen.dart';
import 'route_preview_screen_utils.dart';
import 'route_preview_viewport_controller.dart';

class RoutePreviewScreen extends ConsumerStatefulWidget {
  const RoutePreviewScreen({super.key});

  @override
  ConsumerState<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends ConsumerState<RoutePreviewScreen> {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _showBanner = true;
  bool _hasRequestedLocation = false;
  bool _isOpeningAddressSheet = false;
  RideStatus? _lastStatus;
  final RouteViewportController _viewportController = RouteViewportController();
  bool _isFollowingDriver = false;
  bool _isFollowAnimationInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(selectedDestinationProvider) != null) _expandSheet();
      ref.read(locationTrackingRequestCountProvider.notifier).state++;
      _hasRequestedLocation = true;
    });
  }

  @override
  void dispose() {
    if (_hasRequestedLocation) {
      final notifier = ref.read(locationTrackingRequestCountProvider.notifier);
      notifier.state = notifier.state > 0 ? notifier.state - 1 : 0;
    }
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _hardRefreshRoutePricing() async {
    ref.read(bookingErrorProvider.notifier).state = null;
    ref.read(selectedRouteIndexProvider.notifier).state = 0;
    ref.read(selectedPaymentMethodProvider.notifier).state = PaymentMethod.cash;
    ref.read(lastSelectedCategoryIdProvider.notifier).state = null;
    ref.invalidate(selectedCategoryProvider);
    ref.read(bookingRouteRefreshControllerProvider).clearSnapshotAndRefresh();
    ref.invalidate(routeDirectionsProvider);
    ref.invalidate(rideCategoriesProvider);
    await Future.wait([
      ref.read(routeDirectionsProvider.future),
      ref.read(rideCategoriesProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ridePriceAutoRefreshProvider);
    final directionsAsync = ref.watch(routeDirectionsProvider);
    final destination = ref.watch(selectedDestinationProvider);
    final positionAsync = ref.watch(currentLocationProvider);
    final categories = ref.watch(rideCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedPaymentMethod = ref.watch(selectedPaymentMethodProvider);
    final flowState = ref.watch(bookingFlowProvider);
    final pickup = ref.watch(selectedPickupProvider);
    final selectedRouteIndex = ref.watch(selectedRouteIndexProvider);
    final activeRide = ref.watch(activeRideControllerProvider);
    final liveMetrics = ref.watch(activeRideLiveMetricsControllerProvider);
    final position = positionAsync.asData?.value;
    final originSnapshot = ref.watch(bookingOriginSnapshotProvider);
    final activeRideRouteQuery = ref.watch(activeRideMapRouteQueryProvider);
    final isRideInProgress = flowState == BookingFlowState.inProgress &&
        activeRide?.status == RideStatus.inProgress;

    if (!isRideInProgress && _isFollowingDriver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isFollowingDriver = false;
            _isFollowAnimationInProgress = false;
          });
        }
      });
    }

    ref.listen(
      activeRideControllerProvider.select((r) => r?.driverLocation),
      (_, next) {
        if (next == null || !isRideInProgress || !mounted) return;
        if (!_isFollowingDriver) setState(() => _isFollowingDriver = true);
        _followDriverTo(next);
      },
    );

    final viewportTarget = resolveRoutePreviewViewportTarget(
      flowState: flowState,
      bookingDirections: directionsAsync.asData?.value,
      pickup: pickup,
      destination: destination,
      originSnapshot: originSnapshot,
      position: position,
      activeRide: activeRide,
      activeRideRouteQuery: activeRideRouteQuery,
    );
    _scheduleViewportFitIfNeeded(viewportTarget);

    if (activeRide?.status != _lastStatus) {
      _lastStatus = activeRide?.status;
      _showBanner = true;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPressed(context);
      },
      child: BookingFlowListeners(
        onNavigateToSearch: () =>
            goHomeAndResetSearchState(context, openDestinationSearch: false),
        onOpenDestinationSearch: () =>
            goHomeAndResetSearchState(context, openDestinationSearch: true),
        onExpandSheet: _expandSheet,
        child: Scaffold(
          body: Stack(
            children: [
              RoutePreviewMapStack(
                mapLayer: RouteMapSection(
                  directionsAsync: directionsAsync,
                  position: position,
                  pickup: pickup,
                  destination: destination,
                  onMapCreated: _handleMapCreated,
                  onPickupMarkerTap: (latLng) => _openMapAddressPicker(
                    SearchType.pickup,
                    markerPosition: latLng,
                  ),
                  onDestinationMarkerTap: (latLng) => _openMapAddressPicker(
                    SearchType.destination,
                    markerPosition: latLng,
                  ),
                  onCameraMoveStarted: _handleCameraMoveStarted,
                  onCameraIdle: _handleCameraIdle,
                ),
                directionsAsync: directionsAsync,
                selectedRouteIndex: selectedRouteIndex,
                onBackPressed: () => _handleBackPressed(context),
                flowState: flowState,
                showBanner: _showBanner,
                activeRideStatus: activeRide?.status,
                activeRideArrivedAt: activeRide?.arrivedAt,
                liveDistanceText: liveMetrics.distanceText,
                liveArrivalTimeText: liveMetrics.arrivalTimeText,
                onCloseBanner: () => setState(() => _showBanner = false),
                showResetCameraButton: isRideInProgress
                    ? !_isFollowingDriver
                    : _viewportController.showResetCameraButton,
                onResetCameraPressed: _handleResetCameraPressed,
              ),
              RoutePreviewBottomSheet(
                controller: _sheetController,
                flowState: flowState,
                activeRideStatus: activeRide?.status,
                directionsAsync: directionsAsync,
                destination: destination,
                categories: categories,
                selectedCategory: selectedCategory,
                selectedPaymentMethod: selectedPaymentMethod,
                onCategorySelected: (category) => ref
                    .read(selectedCategoryProvider.notifier)
                    .select(category),
                onPaymentMethodSelected: (method) =>
                    ref.read(selectedPaymentMethodProvider.notifier).state =
                        method,
                onRefreshRoutePricing: _hardRefreshRoutePricing,
                onRefreshRideStatus: () =>
                    ref.read(bookingFlowProvider.notifier).hardRefreshStatus(),
                onEditPickup: () => _openAddressEditor(SearchType.pickup),
                onEditDestination: () =>
                    _openAddressEditor(SearchType.destination),
                onConfirmBooking: () =>
                    ref.read(bookingFlowProvider.notifier).startSearching(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _expandSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.75,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleBackPressed(BuildContext context) {
    handleRoutePreviewBackPressed(
      context,
      flowState: ref.read(bookingFlowProvider),
    );
  }

  void _handleMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_viewportController.hasPendingAutoFit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitCurrentViewport();
      });
    }
  }

  Future<void> _openAddressEditor(SearchType type) async {
    if (_isOpeningAddressSheet || !mounted) return;
    _isOpeningAddressSheet = true;
    try {
      await showPassengerAddressSearchSheet(context, ref, initialType: type);
    } finally {
      _isOpeningAddressSheet = false;
    }
  }

  Future<void> _openMapAddressPicker(
    SearchType type, {
    LatLng? markerPosition,
  }) async {
    final LatLng initial;
    if (markerPosition != null) {
      initial = markerPosition;
    } else {
      final position = ref.read(currentLocationProvider).asData?.value;
      initial = type == SearchType.pickup
          ? resolveInitialPickupLatLng(
              pickup: ref.read(selectedPickupProvider),
              snapshot: ref.read(bookingOriginSnapshotProvider),
              position: position,
              fallback: kAbidjanDefaultLatLng,
            )
          : resolveInitialDestinationLatLng(
              destination: ref.read(selectedDestinationProvider),
              position: position,
              fallback: kAbidjanDefaultLatLng,
            );
    }
    final openTextSearch = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            MapAddressPickerScreen(target: type, initialPosition: initial),
        fullscreenDialog: true,
      ),
    );
    if (openTextSearch == true && mounted) await _openAddressEditor(type);
  }

  void _scheduleViewportFitIfNeeded(RouteViewportTarget? target) {
    final shouldSchedule = _viewportController.syncTarget(target);
    if (!shouldSchedule) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitCurrentViewport();
    });
  }

  void _fitCurrentViewport() {
    final target = _viewportController.currentTarget;
    if (target == null || _mapController == null || !mounted) return;

    _viewportController.markProgrammaticCameraMove();
    animateFitBounds(
      _mapController,
      mounted: mounted,
      origin: target.origin,
      destination: target.destination,
    );
    setState(() {});
  }

  void _followDriverTo(LatLng pos) {
    if (_mapController == null || !mounted) return;
    _isFollowAnimationInProgress = true;
    _mapController!.animateCamera(CameraUpdate.newLatLng(pos)).then((_) {
      if (mounted) _isFollowAnimationInProgress = false;
    });
  }

  void _handleResetCameraPressed() {
    final rideStatus = ref.read(activeRideControllerProvider)?.status;
    final flow = ref.read(bookingFlowProvider);
    if (flow == BookingFlowState.inProgress &&
        rideStatus == RideStatus.inProgress) {
      final pos = ref.read(activeRideControllerProvider)?.driverLocation;
      setState(() => _isFollowingDriver = true);
      if (pos != null) _followDriverTo(pos);
      return;
    }
    _fitCurrentViewport();
  }

  void _handleCameraMoveStarted() {
    if (_isFollowingDriver || _isFollowAnimationInProgress) {
      _isFollowAnimationInProgress = false;
      if (_isFollowingDriver && mounted) setState(() => _isFollowingDriver = false);
      return;
    }
    if (!_viewportController.handleCameraMoveStarted() || !mounted) return;
    setState(() {});
  }

  void _handleCameraIdle() {
    if (!_viewportController.handleCameraIdle() || !mounted) return;
    setState(() {});
  }
}
