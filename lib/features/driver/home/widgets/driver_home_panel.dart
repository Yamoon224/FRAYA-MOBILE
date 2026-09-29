library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import '../providers/driver_home_state.dart';
import 'driver_home_ride_section.dart';
import 'driver_home_summary_section.dart';

const driverHomeBottomPanelSurfaceKey = Key('driver_home_bottom_panel_surface');

class DriverHomePanel extends StatelessWidget {
  const DriverHomePanel({
    super.key,
    required this.scrollController,
    required this.state,
    required this.gate,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
    required this.onCallPassenger,
    required this.onOpenPassengerWhatsApp,
    required this.onArrived,
    required this.onStart,
    required this.onComplete,
    required this.onCancel,
    required this.onOpenEarnings,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final DriverHomeState state;
  final DriverAdminStatusResult gate;
  final bool isBusy;
  final Future<void> Function(DriverRide ride) onAccept;
  final Future<void> Function(DriverRide ride) onDecline;
  final Future<void> Function(DriverRide ride) onCallPassenger;
  final Future<void> Function(DriverRide ride) onOpenPassengerWhatsApp;
  final Future<void> Function(DriverRide ride) onArrived;
  final Future<void> Function(DriverRide ride) onStart;
  final Future<void> Function(DriverRide ride) onComplete;
  final Future<void> Function(DriverRide ride) onCancel;
  final VoidCallback onOpenEarnings;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final showRideSection =
        state.isOnline ||
        state.hasActiveRide ||
        state.availableRides.isNotEmpty;
    final showSummarySection = !state.hasActiveRide;
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomContentPadding = (bottomSafeInset + AppTheme.spacingSm)
        .clamp(18.0, 56.0)
        .toDouble();
    final surfaceColor = context.colors.surface;
    final handleColor = context.colors.greyLight;
    final hPad = context.horizontalPagePadding;

    return Container(
      key: driverHomeBottomPanelSurfaceKey,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
        boxShadow: AppColors.shadowLg,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomContentPadding),
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSummarySection) ...[
                        Text(
                          "Aujourd'hui",
                          style: AppTextStyles.h1.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        DriverHomeSummarySection(
                          state: state,
                          gate: gate,
                          onOpenEarnings: onOpenEarnings,
                        ),
                      ],
                      if (showRideSection) ...[
                        SizedBox(
                          height: showSummarySection
                              ? AppTheme.spacingLg
                              : AppTheme.spacingXs,
                        ),
                        DriverHomeRideSection(
                          isOnline: state.isOnline,
                          isBusy: isBusy,
                          availableRides: state.availableRides,
                          activeRide: state.activeRide,
                          onAccept: onAccept,
                          onDecline: onDecline,
                          onCallPassenger: onCallPassenger,
                          onOpenPassengerWhatsApp: onOpenPassengerWhatsApp,
                          onArrived: onArrived,
                          onStart: onStart,
                          onComplete: onComplete,
                          onCancel: onCancel,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double driverHomePanelHeightFactor(DriverHomeState state) {
  // This helper is kept for backward compatibility in callers that cannot pass
  // BuildContext.
  if (state.hasActiveRide) {
    return 0.56;
  }
  return 0.42;
}

double driverHomePanelHeightFactorForContext(
  BuildContext context,
  DriverHomeState state,
) {
  if (context.isLandscapePhone) {
    return 0.75;
  }
  return driverHomePanelHeightFactor(state);
}
