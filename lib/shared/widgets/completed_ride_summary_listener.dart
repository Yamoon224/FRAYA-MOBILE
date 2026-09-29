import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/router/route_names.dart';
import '../../domain/models/active_ride.dart';
import '../../features/passenger/booking/providers/active_ride_provider.dart';
import '../providers/app_providers.dart';

class CompletedRideSummaryListener extends ConsumerStatefulWidget {
  const CompletedRideSummaryListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<CompletedRideSummaryListener> createState() =>
      _CompletedRideSummaryListenerState();
}

class _CompletedRideSummaryListenerState
    extends ConsumerState<CompletedRideSummaryListener> {
  String? _lastNavigatedRideId;

  @override
  Widget build(BuildContext context) {
    ref.listen<ActiveRide?>(completedRideControllerProvider, (previous, next) {
      _handleCompletedRide(next);
    });
    _handleCompletedRide(ref.watch(completedRideControllerProvider));
    return widget.child;
  }

  void _handleCompletedRide(ActiveRide? ride) {
    if (!AppConfig.instance.isPassenger) return;
    final rideId = ride?.rideId.trim();
    if (rideId == null || rideId.isEmpty) {
      _lastNavigatedRideId = null;
      return;
    }
    if (_lastNavigatedRideId == rideId) return;
    _lastNavigatedRideId = rideId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(appRouterProvider);
      final currentPath = router.routeInformationProvider.value.uri.path;
      if (currentPath == RoutePaths.rideComplete) return;
      router.pushNamed(RouteNames.rideComplete);
    });
  }
}
