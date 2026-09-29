library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../domain/models/driver_ride.dart';
import 'driver_home_arrival_detection.dart';

enum DriverHomeStatus { initial, idle, loading, ready, blocked, error }

class DriverHomeState {
  const DriverHomeState({
    this.status = DriverHomeStatus.initial,
    this.isOnline = false,
    this.canGoOnline = false,
    this.isSubmittingAction = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.availableRides = const [],
    this.ignoredIncomingRideIds = const [],
    this.activeRide,
    this.queuedRide,
    this.isPreArrivalOffersActive = false,
    this.todayEarnings = 0,
    this.todayRideCount = 0,
    this.todayOnlineHours,
    this.todayCompletedRides = const [],
    this.knownCompletedRides = const [],
    this.currentDriverLocation,
    this.currentDriverHeading,
    this.driverRating,
    this.monthlyEarnings,
    this.arrivalDetectionEvent,
  });

  final DriverHomeStatus status;
  final bool isOnline;
  final bool canGoOnline;
  final bool isSubmittingAction;
  final bool isRefreshing;
  final String? errorMessage;
  final List<DriverRide> availableRides;
  final List<String> ignoredIncomingRideIds;
  final DriverRide? activeRide;
  final DriverRide? queuedRide;
  final bool isPreArrivalOffersActive;
  final double todayEarnings;
  final int todayRideCount;
  final double? todayOnlineHours;
  final List<DriverRide> todayCompletedRides;
  final List<DriverRide> knownCompletedRides;
  final LatLng? currentDriverLocation;
  final double? currentDriverHeading;
  final double? driverRating;
  final double? monthlyEarnings;
  final DriverArrivalDetectionEvent? arrivalDetectionEvent;

  bool get hasActiveRide => activeRide != null;
  bool get hasQueuedRide => queuedRide != null;
  bool get hasAvailableRides => availableRides.isNotEmpty;
  bool get isBlocked => status == DriverHomeStatus.blocked;
  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
  bool get canShowIncomingRequests =>
      (activeRide == null || isPreArrivalOffersActive) && !hasQueuedRide;

  DriverHomeState copyWith({
    DriverHomeStatus? status,
    bool? isOnline,
    bool? canGoOnline,
    bool? isSubmittingAction,
    bool? isRefreshing,
    Object? errorMessage = _sentinel,
    List<DriverRide>? availableRides,
    List<String>? ignoredIncomingRideIds,
    Object? activeRide = _sentinel,
    Object? queuedRide = _sentinel,
    bool? isPreArrivalOffersActive,
    double? todayEarnings,
    int? todayRideCount,
    Object? todayOnlineHours = _sentinel,
    List<DriverRide>? todayCompletedRides,
    List<DriverRide>? knownCompletedRides,
    Object? currentDriverLocation = _sentinel,
    Object? currentDriverHeading = _sentinel,
    Object? driverRating = _sentinel,
    Object? monthlyEarnings = _sentinel,
    Object? arrivalDetectionEvent = _sentinel,
  }) {
    return DriverHomeState(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      canGoOnline: canGoOnline ?? this.canGoOnline,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      availableRides: availableRides ?? this.availableRides,
      ignoredIncomingRideIds:
          ignoredIncomingRideIds ?? this.ignoredIncomingRideIds,
      activeRide: identical(activeRide, _sentinel)
          ? this.activeRide
          : activeRide as DriverRide?,
      queuedRide: identical(queuedRide, _sentinel)
          ? this.queuedRide
          : queuedRide as DriverRide?,
      isPreArrivalOffersActive:
          isPreArrivalOffersActive ?? this.isPreArrivalOffersActive,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayRideCount: todayRideCount ?? this.todayRideCount,
      todayOnlineHours: identical(todayOnlineHours, _sentinel)
          ? this.todayOnlineHours
          : todayOnlineHours as double?,
      todayCompletedRides: todayCompletedRides ?? this.todayCompletedRides,
      knownCompletedRides: knownCompletedRides ?? this.knownCompletedRides,
      currentDriverLocation: identical(currentDriverLocation, _sentinel)
          ? this.currentDriverLocation
          : currentDriverLocation as LatLng?,
      currentDriverHeading: identical(currentDriverHeading, _sentinel)
          ? this.currentDriverHeading
          : currentDriverHeading as double?,
      driverRating: identical(driverRating, _sentinel)
          ? this.driverRating
          : driverRating as double?,
      monthlyEarnings: identical(monthlyEarnings, _sentinel)
          ? this.monthlyEarnings
          : monthlyEarnings as double?,
      arrivalDetectionEvent: identical(arrivalDetectionEvent, _sentinel)
          ? this.arrivalDetectionEvent
          : arrivalDetectionEvent as DriverArrivalDetectionEvent?,
    );
  }
}

const Object _sentinel = Object();
