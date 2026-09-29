/// Ecran d'accueil chauffeur.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/driver_offer_sound_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/realtime/realtime_events.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../data/sources/local_storage.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/main_app_zone_provider.dart';
import '../../../../shared/providers/realtime_providers.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../../../shared/widgets/fraya_dialog.dart';
import '../../../../shared/widgets/ride_cancelled_alert_dialog.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../settings/providers/driver_settings_provider.dart';
import '../widgets/driver_home_incoming_request_bubble.dart';
import '../widgets/driver_home_map_stage.dart';
import '../providers/driver_navigation_launcher_provider.dart';
import '../providers/driver_contact_provider.dart';
import '../providers/driver_home_vehicle_color_provider.dart';
import '../providers/driver_home_provider.dart';
import '../providers/driver_home_state.dart';
import '../widgets/driver_active_ride_banner.dart';
import '../widgets/driver_arrival_confirmation_dialog.dart';
import '../widgets/driver_cancel_ride_confirmation_dialog.dart';
import '../widgets/driver_drawer.dart';
import '../widgets/driver_home_panel.dart';
import '../widgets/driver_home_queued_ride_banner.dart';
import '../widgets/driver_home_top_bar.dart';

part 'driver_home_screen_helpers.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DriverOfferSoundService _driverOfferSoundService =
      DriverOfferSoundService();
  bool _hasRequestedLocation = false;
  bool _pollingPausedForIncomingRequest = false;
  bool _isNavigationLaunchInProgress = false;
  bool _isRideMinimized = false;
  bool _showLoader = true;
  bool _loaderOpaque = true;
  Timer? _locationRequestTimer;
  StateController<int>? _locationRequestCountController;
  bool _isRideStatusDialogVisible = false;
  bool _isRideCancellationDialogVisible = false;
  bool _isArrivalPromptDialogVisible = false;
  final Set<String> _notifiedRideExitIds = <String>{};
  final Set<String> _locallyCancelledRideIds = <String>{};
  String? _lastDriverStatusNotificationKey;
  String? _lastArrivalPromptKey;
  StateController<bool>? _mainAppZoneController;

  void _restoreRidePanelAfterCancellation() {
    if (!mounted || !_isRideMinimized) return;
    setState(() => _isRideMinimized = false);
  }

  void _dismissLoader() {
    if (!_showLoader || !mounted) return;
    setState(() => _loaderOpaque = false);
    Future.delayed(const Duration(milliseconds: 480), () {
      if (mounted) setState(() => _showLoader = false);
    });
  }

  void _dismissLoaderIfReady() {
    final homeStatus = ref.read(driverHomeProvider).status;
    final stillInitializing =
        homeStatus == DriverHomeStatus.initial ||
        homeStatus == DriverHomeStatus.loading;
    if (stillInitializing) return;

    _dismissLoader();
  }

  @override
  void initState() {
    super.initState();
    // Dismiss loader immediately if the home state is already resolved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dismissLoaderIfReady();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationRequestTimer?.cancel();
      _locationRequestTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _locationRequestCountController ??= ref.read(
          locationTrackingRequestCountProvider.notifier,
        );
        _locationRequestCountController!.state++;
        _hasRequestedLocation = true;
        _mainAppZoneController ??= ref.read(mainAppZoneProvider.notifier);
        _mainAppZoneController!.state = true;
      });
    });
  }

  @override
  void dispose() {
    _locationRequestTimer?.cancel();
    unawaited(_driverOfferSoundService.dispose());
    final notifier = _locationRequestCountController;
    if (_hasRequestedLocation && notifier != null) {
      Future<void>.microtask(() {
        try {
          notifier.state = notifier.state > 0 ? notifier.state - 1 : 0;
        } catch (_) {
          // Ignore when the backing provider container is already disposed.
        }
      });
    }
    final zoneNotifier = _mainAppZoneController;
    if (zoneNotifier != null) {
      Future<void>.microtask(() {
        try {
          zoneNotifier.state = false;
        } catch (_) {}
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenHomeState(context);
    _listenRealtimeRideStatus();
    _listenDriverSettings();
    _listenArrivalDetection(context);

    ref.listen(driverHomeProvider, (prev, next) {
      _dismissLoaderIfReady();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(driverAuthProvider);
    final homeState = ref.watch(driverHomeProvider);
    final visibleIncomingRides = homeState.availableRides;
    final hasActiveRide = homeState.activeRide != null;
    final effectiveIsRideMinimized = _isRideMinimized && hasActiveRide;
    final gate = DriverAdminStatusGate.fromUserData(authState.userData);
    final hasIncomingRequest =
        homeState.isOnline &&
        homeState.canShowIncomingRequests &&
        homeState.availableRides.isNotEmpty;
    final hasVisibleIncomingRequest = hasIncomingRequest;
    final isIncomingPopupVisible = hasIncomingRequest;
    final panelHeightFactor = driverHomePanelHeightFactorForContext(
      context,
      effectiveIsRideMinimized
          ? homeState.copyWith(activeRide: null)
          : homeState,
    );
    final mapBottomPaddingFactor = isIncomingPopupVisible
        ? 0.0
        : panelHeightFactor;
    final driverMarkerColor = ref.watch(driverVehicleMarkerColorProvider);
    final driverMarkerPosition =
        homeState.currentDriverLocation ?? homeState.activeRide?.driverLocation;
    final driverMarkerHeading = homeState.currentDriverHeading;
    final isActionBusy =
        homeState.isSubmittingAction ||
        homeState.status == DriverHomeStatus.loading;
    final isTopBarBusy = homeState.isRefreshing || isActionBusy;
    final canOpenNavigation = _canOpenNavigation(homeState.activeRide);
    final panelState = homeState.copyWith(
      availableRides: visibleIncomingRides,
      activeRide: effectiveIsRideMinimized ? null : homeState.activeRide,
    );
    final incomingPopupTopPadding = MediaQuery.paddingOf(context).top + 104;
    final backgroundColor = context.colors.background;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const DriverDrawer(),
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DriverHomeMapStage(
              bottomPadding:
                  MediaQuery.sizeOf(context).height * mapBottomPaddingFactor,
              driverMarkerColor: driverMarkerColor,
              driverMarkerPosition: driverMarkerPosition,
              driverMarkerHeading: driverMarkerHeading,
              activeRide: homeState.activeRide,
            ),
          ),
          if (hasVisibleIncomingRequest)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: context.responsiveBody(
                Padding(
                  padding: context.overlayPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DriverHomeTopBar(
                        isOnline: homeState.isOnline,
                        isBusy: isTopBarBusy,
                        canToggleOnline: _canToggleOnline(homeState),
                        showStatusToggle:
                            homeState.activeRide == null ||
                            effectiveIsRideMinimized,
                        isNavigationEnabled: canOpenNavigation,
                        onToggleOnline: (value) {
                          ref
                              .read(driverHomeProvider.notifier)
                              .setOnline(value);
                        },
                        onMenuPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        onMoneyPressed: () {
                          context.pushNamed(RouteNames.driverWallet);
                        },
                        onNavigationPressed: canOpenNavigation
                            ? () => _openExternalNavigation(
                                context,
                                homeState.activeRide!,
                              )
                            : null,
                        onBackToHome: hasActiveRide
                            ? () => setState(() => _isRideMinimized = true)
                            : null,
                      ),
                      if (effectiveIsRideMinimized) ...[
                        const SizedBox(height: 8),
                        DriverActiveRideBanner(
                          onTap: () => setState(() => _isRideMinimized = false),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!isIncomingPopupVisible &&
              !effectiveIsRideMinimized &&
              (homeState.isOnline || hasActiveRide || homeState.isBlocked))
            Positioned(
              top:
                  MediaQuery.paddingOf(context).top + (hasActiveRide ? 14 : 84),
              left: 0,
              right: 0,
              child: context.responsiveBody(
                DriverHomeFloatingStatusBadge(
                  label: _statusLabel(homeState),
                  color: _statusColor(homeState),
                ),
              ),
            ),
          if (isIncomingPopupVisible)
            Positioned.fill(
              child: DriverHomeIncomingRequestBubble(
                availableRides: homeState.availableRides,
                topPadding: incomingPopupTopPadding,
                isBusy: isActionBusy,
                onAccept: (ride) async {
                  final notifier = ref.read(driverHomeProvider.notifier);
                  unawaited(_driverOfferSoundService.stopIncomingRideAlert());
                  // Conserve le polling en pause après acceptation.
                  _pollingPausedForIncomingRequest = true;
                  final accepted = await notifier.acceptRide(ride.rideId);
                  if (!accepted && mounted) {
                    _pollingPausedForIncomingRequest = false;
                    await notifier.resumePollingAfterIncomingDecision(
                      refreshNow: true,
                    );
                    final refreshedState = ref.read(driverHomeProvider);
                    if (ref.read(driverSettingsProvider).soundsEnabled &&
                        _hasVisibleIncomingRequestForState(refreshedState)) {
                      unawaited(
                        _driverOfferSoundService.playIncomingRideAlert(),
                      );
                    }
                  }
                },
                onDecline: (ride) async {
                  final notifier = ref.read(driverHomeProvider.notifier);
                  await notifier.declineRideLocally(ride.rideId);
                  unawaited(_driverOfferSoundService.stopIncomingRideAlert());
                  _pollingPausedForIncomingRequest = false;
                  await notifier.resumePollingAfterIncomingDecision(
                    refreshNow: true,
                  );
                  final refreshedState = ref.read(driverHomeProvider);
                  if (ref.read(driverSettingsProvider).soundsEnabled &&
                      _hasVisibleIncomingRequestForState(refreshedState)) {
                    unawaited(_driverOfferSoundService.playIncomingRideAlert());
                  }
                },
                onExpired: (ride) async {
                  final notifier = ref.read(driverHomeProvider.notifier);
                  await notifier.declineRideLocally(ride.rideId);
                  unawaited(_driverOfferSoundService.stopIncomingRideAlert());
                  _pollingPausedForIncomingRequest = false;
                  await notifier.resumePollingAfterIncomingDecision(
                    refreshNow: true,
                  );
                  final refreshedState = ref.read(driverHomeProvider);
                  if (ref.read(driverSettingsProvider).soundsEnabled &&
                      _hasVisibleIncomingRequestForState(refreshedState)) {
                    unawaited(_driverOfferSoundService.playIncomingRideAlert());
                  }
                },
              ),
            )
          else
            DraggableScrollableSheet(
              key: ValueKey(panelState.hasActiveRide),
              initialChildSize: panelHeightFactor,
              minChildSize: context.responsiveValue<double>(
                compact: 0.22,
                phone: 0.22,
                largePhone: 0.20,
                tablet: 0.18,
              ),
              maxChildSize: 0.92,
              snap: true,
              snapSizes: [panelHeightFactor],
              builder: (context, scrollController) {
                final screenWidth = MediaQuery.sizeOf(context).width;
                final maxWidth = context.contentMaxWidthForOrientation;
                final sidePad = ((screenWidth - maxWidth) / 2).clamp(
                  0.0,
                  double.infinity,
                );
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: sidePad),
                  child: DriverHomePanel(
                    scrollController: scrollController,
                    state: panelState,
                    gate: gate,
                    isBusy: isActionBusy,
                    onAccept: (ride) async {
                      await ref
                          .read(driverHomeProvider.notifier)
                          .acceptRide(ride.rideId);
                    },
                    onDecline: (ride) async {
                      await ref
                          .read(driverHomeProvider.notifier)
                          .declineRideLocally(ride.rideId);
                    },
                    onCallPassenger: (ride) => _callPassenger(context, ride),
                    onOpenPassengerWhatsApp: (ride) =>
                        _openPassengerWhatsApp(context, ride),
                    onArrived: (ride) => _markArrived(ref, ride),
                    onStart: (ride) async {
                      await ref
                          .read(driverHomeProvider.notifier)
                          .startRide(ride.rideId);
                    },
                    onComplete: (ride) => _completeRide(context, ride),
                    onCancel: (ride) async {
                      final confirmed =
                          await showDriverCancelRideConfirmationDialog(context);
                      if (!context.mounted || !confirmed) return;
                      _locallyCancelledRideIds.add(ride.rideId);
                      final cancelled = await ref
                          .read(driverHomeProvider.notifier)
                          .cancelRide(
                            rideId: ride.rideId,
                            reason: 'Annulation chauffeur',
                          );
                      if (!context.mounted) return;
                      if (!cancelled) {
                        _locallyCancelledRideIds.remove(ride.rideId);
                        return;
                      }
                      AppSnackBar.showSuccess(
                        context,
                        'Course annulée avec succès.',
                      );
                      _restoreRidePanelAfterCancellation();
                    },
                    onOpenEarnings: () {
                      context.pushNamed(RouteNames.driverEarnings);
                    },
                    onRefresh: () =>
                        ref.read(driverHomeProvider.notifier).refreshHome(),
                  ),
                );
              },
            ),
          if (homeState.hasQueuedRide && !isIncomingPopupVisible)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.sizeOf(context).height * panelHeightFactor + 8,
              child: context.responsiveBody(
                DriverHomeQueuedRideBanner(ride: homeState.queuedRide!),
              ),
            ),
          if (_showLoader)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_loaderOpaque,
                child: AnimatedOpacity(
                  opacity: _loaderOpaque ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOut,
                  child: _DriverHomeLoadingOverlay(isDark: isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DriverHomeLoadingOverlay extends StatefulWidget {
  const _DriverHomeLoadingOverlay({required this.isDark});

  final bool isDark;

  @override
  State<_DriverHomeLoadingOverlay> createState() =>
      _DriverHomeLoadingOverlayState();
}

class _DriverHomeLoadingOverlayState extends State<_DriverHomeLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = context.colors.background;
    final subtitleColor = context.colors.textTertiary;

    return ColoredBox(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _pulseAnimation,
              child: ShaderMask(
                shaderCallback: (rect) =>
                    AppColors.goldGradient.createShader(rect),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'FRAYA',
                  style: AppTextStyles.h1.copyWith(
                    fontSize: context.responsiveValue<double>(
                      compact: 32,
                      phone: 38,
                      largePhone: 42,
                      tablet: 48,
                    ),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'TAXI',
              style: AppTextStyles.small.copyWith(
                color: subtitleColor,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
