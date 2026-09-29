import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/home_navigation_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/map_icons_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../../../shared/widgets/map/fraya_map.dart';
import '../../../../core/router/route_names.dart';
import '../../../passenger/booking/providers/booking_flow_provider.dart';
import '../../../passenger/map/providers/nearby_drivers_provider.dart';
import '../providers/home_search_state_controller.dart';
import '../widgets/address_search_sheet_launcher.dart';
import '../widgets/passenger_drawer.dart';
import '../widgets/home_address_pill.dart';
import '../widgets/home_menu_button.dart';
import '../widgets/home_bottom_sheet.dart';
import '../widgets/active_ride_banner.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _navSub;
  StreamSubscription<void>? _resetSearchSub;
  StreamSubscription<void>? _openVehicleSelectionSub;
  bool _isOpeningDestinationSearchSheet = false;
  bool _showLoader = true;
  bool _loaderOpaque = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navSub = HomeNavigationNotifier.instance.openSearchEvents.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openDestinationSearchSheet();
      });
    });
    _resetSearchSub = HomeNavigationNotifier.instance.resetSearchStateEvents
        .listen((_) {
          if (!mounted) return;
          HomeNavigationNotifier.instance
              .consumeResetSearchStateOnHomePending();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref
                .read(homeSearchStateControllerProvider)
                .resetAfterBookingReturn();
          });
        });
    _openVehicleSelectionSub = HomeNavigationNotifier
        .instance
        .openVehicleSelectionEvents
        .listen((_) {
          if (!mounted) return;
          context.pushNamed(RouteNames.vehicleSelection);
        });
    final shouldResetSearchState = HomeNavigationNotifier.instance
        .consumeResetSearchStateOnHomePending();
    if (shouldResetSearchState) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(homeSearchStateControllerProvider).resetAfterBookingReturn();
      });
    }
    final shouldOpenPendingSearch = HomeNavigationNotifier.instance
        .consumeOpenDestinationSearchOnHomePending();
    if (shouldOpenPendingSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openDestinationSearchSheet();
      });
    }

    // Handle the case where location is already resolved on mount (revisit).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final readiness = ref.read(passengerLocationReadinessProvider);
      if (readiness != PassengerLocationReadiness.loading) {
        _dismissLoader();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navSub?.cancel();
    _resetSearchSub?.cancel();
    _openVehicleSelectionSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future<void>(() {
        if (!mounted) return;
        _refreshPassengerSnapshot();
      });
    }
  }

  void _dismissLoader() {
    if (!_showLoader || !mounted) return;
    setState(() => _loaderOpaque = false);
    Future.delayed(const Duration(milliseconds: 480), () {
      if (mounted) setState(() => _showLoader = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    _openDestinationSearchFromPendingIfNeeded();

    ref.listen(passengerLocationReadinessProvider, (prev, next) {
      if (next != PassengerLocationReadiness.loading) {
        _dismissLoader();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passengerPositionAsync = ref.watch(passengerLocationSnapshotProvider);
    final passengerPosition = passengerPositionAsync.asData?.value;
    final passengerAddress = ref.watch(passengerFormattedAddressProvider);
    final horizontalPadding = context.responsiveValue<double>(
      compact: 12,
      phone: AppTheme.spacingMd,
      largePhone: 20,
      tablet: AppTheme.spacingLg,
    );
    final topSpacing = context.responsiveValue<double>(
      compact: 8,
      phone: 12,
      largePhone: 14,
      tablet: AppTheme.spacingMd,
    );
    final overlaySpacing = context.responsiveValue<double>(
      compact: 10,
      phone: 12,
      largePhone: 14,
      tablet: 16,
    );

    final nearbyDrivers = ref.watch(nearbyDriversProvider);
    final defaultDriverIcon = ref
        .watch(driverCarSvgIconProvider(null))
        .asData
        ?.value;
    final nearbyDriverIcons = <String, BitmapDescriptor>{};
    for (final driver in nearbyDrivers) {
      final icon = ref
          .watch(driverCarSvgIconProvider(driver.vehicleColorRaw))
          .asData
          ?.value;
      if (icon != null) nearbyDriverIcons[driver.id] = icon;
    }
    final driverMarkers = <Marker>{
      if (defaultDriverIcon != null)
        for (final driver in nearbyDrivers)
          Marker(
            markerId: MarkerId(driver.id),
            position: driver.location,
            icon: nearbyDriverIcons[driver.id] ?? defaultDriverIcon,
            rotation: driver.bearing,
            flat: true,
            anchor: const Offset(0.5, 0.5),
          ),
    };
    final mapBottomPad = _mapBottomPadding(context);
    final homeSheetDefaultSize = context.responsiveValue<double>(
      compact: 0.42,
      phone: 0.40,
      largePhone: 0.38,
      tablet: 0.35,
    );
    final homeSheetMinSize = context.responsiveValue<double>(
      compact: 0.22,
      phone: 0.22,
      largePhone: 0.20,
      tablet: 0.18,
    );

    ref.listen(selectedDestinationProvider, (previous, next) {
      final flowState = ref.read(bookingFlowProvider);
      if (next != null &&
          next != previous &&
          flowState == BookingFlowState.idle) {
        context.pushNamed(RouteNames.vehicleSelection);
      }
    });

    return Scaffold(
      drawer: const PassengerDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: FrayaMap(
              markers: driverMarkers,
              initialZoom: 16,
              padding: EdgeInsets.only(bottom: mapBottomPad),
              userPosition: passengerPosition,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topSpacing,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HomeMenuButton(),
                          SizedBox(
                            width: context.responsiveValue<double>(
                              compact: 10,
                              phone: AppTheme.spacingMd,
                              largePhone: AppTheme.spacingMd,
                              tablet: 18,
                            ),
                          ),
                          Expanded(
                            child: HomeAddressPill(
                              addressText: passengerAddress,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: overlaySpacing),
                      const ActiveRideBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: homeSheetDefaultSize,
            minChildSize: homeSheetMinSize,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: [homeSheetDefaultSize],
            builder: (context, scrollController) {
              final screenWidth = MediaQuery.sizeOf(context).width;
              final maxWidth = context.contentMaxWidth;
              final sidePad = ((screenWidth - maxWidth) / 2).clamp(
                0.0,
                double.infinity,
              );
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: HomeBottomSheet(scrollController: scrollController),
              );
            },
          ),
          if (_showLoader)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_loaderOpaque,
                child: AnimatedOpacity(
                  opacity: _loaderOpaque ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOut,
                  child: _HomeLoadingOverlay(isDark: isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _mapBottomPadding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final ratioPadding =
        size.height *
        context.responsiveValue<double>(
          compact: 0.56,
          phone: 0.52,
          largePhone: 0.46,
          tablet: 0.36,
        );
    final minPadding = context.responsiveValue<double>(
      compact: 220,
      phone: 250,
      largePhone: 280,
      tablet: 300,
    );
    final maxPadding = (size.height - topInset - 140).clamp(220, size.height);
    return ratioPadding.clamp(minPadding, maxPadding).toDouble();
  }

  void _openDestinationSearchSheet() {
    if (_isOpeningDestinationSearchSheet) return;
    HomeNavigationNotifier.instance.consumeOpenDestinationSearchOnHomePending();
    _isOpeningDestinationSearchSheet = true;
    showPassengerAddressSearchSheet(
      context,
      ref,
    ).whenComplete(() => _isOpeningDestinationSearchSheet = false);
  }

  void _openDestinationSearchFromPendingIfNeeded() {
    final notifier = HomeNavigationNotifier.instance;
    if (_isOpeningDestinationSearchSheet) return;
    if (!notifier.hasOpenDestinationSearchOnHomePending) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openDestinationSearchSheet();
    });
  }

  void _refreshPassengerSnapshot() {
    ref.read(passengerLocationSnapshotRefreshTriggerProvider.notifier).state++;
  }
}

class _HomeLoadingOverlay extends StatefulWidget {
  const _HomeLoadingOverlay({required this.isDark});

  final bool isDark;

  @override
  State<_HomeLoadingOverlay> createState() => _HomeLoadingOverlayState();
}

class _HomeLoadingOverlayState extends State<_HomeLoadingOverlay>
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
    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
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
