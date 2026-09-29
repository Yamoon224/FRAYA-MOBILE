library;

import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';

import '../../../../domain/models/driver_ride.dart';
import 'driver_home_incoming_request_parts.dart';

class DriverHomeIncomingRequestBubble extends StatefulWidget {
  const DriverHomeIncomingRequestBubble({
    super.key,
    required this.availableRides,
    required this.topPadding,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
    required this.onExpired,
  });

  final List<DriverRide> availableRides;
  final double topPadding;
  final bool isBusy;
  final Future<void> Function(DriverRide ride) onAccept;
  final Future<void> Function(DriverRide ride) onDecline;
  final Future<void> Function(DriverRide ride) onExpired;

  @override
  State<DriverHomeIncomingRequestBubble> createState() =>
      _DriverHomeIncomingRequestBubbleState();
}

class _DriverHomeIncomingRequestBubbleState
    extends State<DriverHomeIncomingRequestBubble> {
  static const _expirationDuration = Duration(seconds: 30);
  Timer? _expirationTimer;
  String? _trackedRideId;
  int _remainingSeconds = _expirationDuration.inSeconds;

  @override
  void initState() {
    super.initState();
    _syncExpirationTimer();
  }

  @override
  void didUpdateWidget(covariant DriverHomeIncomingRequestBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncExpirationTimer();
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }

  DriverRide? _firstVisibleRide() {
    return widget.availableRides.isEmpty ? null : widget.availableRides.first;
  }

  void _syncExpirationTimer() {
    final visibleRide = _firstVisibleRide();
    if (visibleRide == null) {
      _stopExpirationTimer();
      return;
    }
    if (_trackedRideId == visibleRide.rideId && _expirationTimer != null) {
      return;
    }
    _startExpirationTimer(visibleRide.rideId);
  }

  void _startExpirationTimer(String rideId) {
    _expirationTimer?.cancel();
    _trackedRideId = rideId;
    _remainingSeconds = _expirationDuration.inSeconds;
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || widget.isBusy) {
        return;
      }
      if (_remainingSeconds <= 1) {
        _expireTrackedRide();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _stopExpirationTimer() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
    _trackedRideId = null;
    _remainingSeconds = _expirationDuration.inSeconds;
  }

  void _expireTrackedRide() {
    final ride = _firstVisibleRide();
    if (ride == null || ride.rideId != _trackedRideId) {
      _syncExpirationTimer();
      return;
    }
    _stopExpirationTimer();
    unawaited(widget.onExpired(ride));
  }

  @override
  Widget build(BuildContext context) {
    final visibleRides = widget.availableRides;
    if (visibleRides.isEmpty) {
      return const SizedBox.shrink();
    }
    final size = MediaQuery.sizeOf(context);
    final ratio = context.isLandscapePhone ? 0.72 : 0.50;
    final cardHeight = size.height * ratio;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: widget.topPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: cardHeight.clamp(
              300.0,
              context.isLandscapePhone ? 420.0 : 500.0,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 26,
                  offset: Offset(0, 16),
                ),
              ],
              border: Border.all(color: context.colors.border),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: IncomingRequestContent(
              ride: visibleRides.first,
              pendingCount: visibleRides.length,
              secondsRemaining: _remainingSeconds,
              isBusy: widget.isBusy,
              onAccept: () => widget.onAccept(visibleRides.first),
              onDecline: () => widget.onDecline(visibleRides.first),
            ),
          ),
        ),
      ),
    );
  }
}
