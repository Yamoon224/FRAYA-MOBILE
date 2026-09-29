import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/ride_status.dart';
import '../models/booking_flow_state.dart';
import 'active_ride/ride_status_banner.dart';
import 'top_action_buttons.dart';

class RoutePreviewMapStack extends StatelessWidget {
  const RoutePreviewMapStack({
    super.key,
    required this.mapLayer,
    required this.directionsAsync,
    required this.selectedRouteIndex,
    required this.onBackPressed,
    required this.flowState,
    required this.showBanner,
    required this.activeRideStatus,
    required this.activeRideArrivedAt,
    required this.liveDistanceText,
    required this.liveArrivalTimeText,
    required this.onCloseBanner,
    required this.showResetCameraButton,
    required this.onResetCameraPressed,
  });

  final Widget mapLayer;
  final AsyncValue<DirectionsResult?> directionsAsync;
  final int selectedRouteIndex;
  final VoidCallback onBackPressed;
  final BookingFlowState flowState;
  final bool showBanner;
  final RideStatus? activeRideStatus;
  final DateTime? activeRideArrivedAt;
  final String? liveDistanceText;
  final String? liveArrivalTimeText;
  final VoidCallback onCloseBanner;
  final bool showResetCameraButton;
  final VoidCallback onResetCameraPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: mapLayer),
        TopActionButtons(
          onBackPressed: onBackPressed,
          arrivalTime: _arrivalTime,
        ),
        if (showResetCameraButton)
          Positioned(
            right: AppTheme.spacingMd,
            bottom: _resetButtonBottomOffset(context, flowState),
            child: _ResetCameraButton(onPressed: onResetCameraPressed),
          ),
        if (showBanner &&
            (flowState == BookingFlowState.driverAssigned ||
                flowState == BookingFlowState.arrived))
          Positioned(
            top: MediaQuery.paddingOf(context).top + 65,
            left: 0,
            right: 0,
            child: RideStatusBanner(
              status: activeRideStatus ?? RideStatus.pending,
              arrivedAt: activeRideArrivedAt,
              distance: liveDistanceText,
              onClose: onCloseBanner,
            ),
          ),
      ],
    );
  }

  String? get _arrivalTime =>
      activeRideStatus == RideStatus.accepted ? liveArrivalTimeText : null;

  double _resetButtonBottomOffset(
    BuildContext context,
    BookingFlowState flowState,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetRatio =
        flowState == BookingFlowState.driverAssigned ||
            flowState == BookingFlowState.arrived ||
            flowState == BookingFlowState.inProgress
        ? context.responsiveValue<double>(
            compact: 0.52,
            phone: 0.48,
            largePhone: 0.46,
            tablet: 0.42,
          )
        : 0.35;
    return (screenHeight * sheetRatio) + AppTheme.spacingMd;
  }
}

class _ResetCameraButton extends StatelessWidget {
  const _ResetCameraButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
        boxShadow: AppColors.shadowMd,
      ),
      child: IconButton(
        key: const Key('passenger_map_reset_camera_button'),
        tooltip: 'Recentrer la carte',
        icon: Icon(
          Icons.center_focus_strong_rounded,
          color: context.colors.textPrimary,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
