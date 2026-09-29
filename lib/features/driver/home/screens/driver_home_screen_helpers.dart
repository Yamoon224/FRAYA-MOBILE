part of 'driver_home_screen.dart';

extension _DriverHomeScreenHelpers on _DriverHomeScreenState {
  void _listenHomeState(BuildContext context) {
    ref.listen<DriverHomeState>(driverHomeProvider, (previous, next) {
      final hadVisibleIncomingRequest =
          previous != null && _hasVisibleIncomingRequestForState(previous);
      final hasVisibleIncomingRequest = _hasVisibleIncomingRequestForState(
        next,
      );
      if (hasVisibleIncomingRequest && !_pollingPausedForIncomingRequest) {
        _pollingPausedForIncomingRequest = true;
        ref.read(driverHomeProvider.notifier).pausePollingForIncomingRequest();
      }
      if (hasVisibleIncomingRequest &&
          !hadVisibleIncomingRequest &&
          ref.read(driverSettingsProvider).soundsEnabled) {
        unawaited(_driverOfferSoundService.playIncomingRideAlert());
      } else if (!hasVisibleIncomingRequest && hadVisibleIncomingRequest) {
        unawaited(_driverOfferSoundService.stopIncomingRideAlert());
      }
      if (!(previous?.isOnline ?? false) && next.isOnline) {
        unawaited(_requestPushPermissionOnce());
      }
      final nextError = next.errorMessage?.trim();
      final previousError = previous?.errorMessage?.trim();
      if (nextError != null &&
          nextError.isNotEmpty &&
          nextError != previousError &&
          context.mounted) {
        AppSnackBar.showError(context, nextError);
      }

      final previousRide = previous?.activeRide;
      final lostActiveRide = previousRide != null && next.activeRide == null;
      final actionInFlight =
          (previous?.isSubmittingAction ?? false) || next.isSubmittingAction;
      if (lostActiveRide && !actionInFlight) {
        final rideId = previousRide.rideId;
        final locallyCancelled = _locallyCancelledRideIds.remove(rideId);
        if (locallyCancelled) {
          _notifiedRideExitIds.add(rideId);
        } else if (!_notifiedRideExitIds.contains(rideId)) {
          _notifiedRideExitIds.add(rideId);
          unawaited(
            _showRideCancelledDialog('Cette course a été clôturée ou annulée.'),
          );
        }
      }
      if (next.activeRide != null) {
        _notifiedRideExitIds.remove(next.activeRide!.rideId);
      }
    });
  }

  void _listenDriverSettings() {
    ref.listen<DriverSettingsState>(driverSettingsProvider, (previous, next) {
      final hadSoundsEnabled = previous?.soundsEnabled ?? true;
      if (hadSoundsEnabled == next.soundsEnabled) return;

      if (!next.soundsEnabled) {
        unawaited(_driverOfferSoundService.stopIncomingRideAlert());
        return;
      }

      if (_hasVisibleIncomingRequestForState(ref.read(driverHomeProvider))) {
        unawaited(_driverOfferSoundService.playIncomingRideAlert());
      }
    });
  }

  void _listenRealtimeRideStatus() {
    ref.listen<DriverRideStatusRealtimeEvent?>(
      driverRideStatusRealtimeProvider,
      (previous, next) {
        if (next == null) return;
        final notificationKey =
            '${next.rideId}|${next.status}|${next.updatedAt.toIso8601String()}';
        if (_lastDriverStatusNotificationKey == notificationKey) return;
        _lastDriverStatusNotificationKey = notificationKey;
        final alreadyNotified = _notifiedRideExitIds.contains(next.rideId);
        final locallyCancelled = _locallyCancelledRideIds.contains(next.rideId);
        if (next.isCancelled || next.isCompleted) {
          _notifiedRideExitIds.add(next.rideId);
          unawaited(
            ref.read(driverHomeProvider.notifier).applyRealtimeRideStatus(next),
          );
        }

        if (next.isCancelled) {
          final cancelledByDriver = next.changeActor == RideChangeActor.driver;
          if (locallyCancelled || cancelledByDriver || alreadyNotified) {
            _locallyCancelledRideIds.remove(next.rideId);
            return;
          }
          final reason = next.reason?.trim();
          final message = (reason != null && reason.isNotEmpty)
              ? 'Le passager a annulé la course.\n\nMotif : $reason'
              : 'Le passager a annulé la course.';
          unawaited(_showRideCancelledDialog(message));
          return;
        }
        if (next.isCompleted) {
          _showRideStatusPopup(
            title: 'Course terminée',
            message: 'La course a été terminée.',
          );
        }
      },
    );
  }

  void _listenArrivalDetection(BuildContext context) {
    ref.listen<DriverHomeState>(driverHomeProvider, (previous, next) {
      final event = next.arrivalDetectionEvent;
      if (event == null) return;
      final key = '${event.rideId}|${event.detectedAt.toIso8601String()}';
      if (_lastArrivalPromptKey == key) return;
      _lastArrivalPromptKey = key;

      final ride = next.activeRide;
      if (ride == null ||
          ride.rideId != event.rideId ||
          ride.status != RideStatus.inProgress) {
        return;
      }
      unawaited(_promptArrivalConfirmation(context, ride));
    });
  }

  Future<void> _promptArrivalConfirmation(
    BuildContext context,
    DriverRide ride,
  ) async {
    if (!context.mounted || _isArrivalPromptDialogVisible) return;
    _isArrivalPromptDialogVisible = true;
    try {
      final confirmed = await showDriverArrivalConfirmationDialog(context);
      if (!context.mounted || !confirmed) return;
      await _completeRide(context, ride);
    } finally {
      _isArrivalPromptDialogVisible = false;
    }
  }

  bool _hasIncomingRequestForState(DriverHomeState state) {
    return state.isOnline &&
        state.canShowIncomingRequests &&
        state.availableRides.isNotEmpty;
  }

  bool _hasVisibleIncomingRequestForState(DriverHomeState state) {
    return _hasIncomingRequestForState(state);
  }

  bool _canToggleOnline(DriverHomeState state) {
    if (state.isSubmittingAction || state.status == DriverHomeStatus.loading) {
      return false;
    }
    return state.canGoOnline || state.isOnline;
  }

  String _statusLabel(DriverHomeState state) {
    final ride = state.activeRide;
    if (ride == null) {
      return state.isBlocked
          ? 'Validation requise'
          : state.isOnline
          ? 'En ligne'
          : 'Hors ligne';
    }
    switch (ride.status) {
      case RideStatus.accepted:
        return 'En route vers le passager';
      case RideStatus.arrived:
        return 'Arrivé - En attente';
      case RideStatus.inProgress:
        return 'Course en cours';
      default:
        return 'Course active';
    }
  }

  Color _statusColor(DriverHomeState state) {
    final ride = state.activeRide;
    if (ride == null) {
      if (state.isBlocked) return const Color(0xFFF59E0B);
      return state.isOnline ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB);
    }
    switch (ride.status) {
      case RideStatus.accepted:
      case RideStatus.arrived:
        return const Color(0xFF22C55E);
      case RideStatus.inProgress:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFFDB913);
    }
  }

  Future<void> _markArrived(WidgetRef ref, DriverRide ride) async {
    await ref.read(driverHomeProvider.notifier).markArrivedForRide(ride);
  }

  Future<void> _completeRide(BuildContext context, DriverRide ride) async {
    context.pushNamed(RouteNames.driverStatus, extra: ride);
  }

  Future<void> _callPassenger(BuildContext context, DriverRide ride) async {
    final opened = await ref
        .read(driverContactControllerProvider)
        .callPassenger(ride);
    if (!context.mounted || opened) return;
    AppSnackBar.showError(
      context,
      'Numéro du passager indisponible pour l\'appel.',
    );
  }

  Future<void> _openPassengerWhatsApp(
    BuildContext context,
    DriverRide ride,
  ) async {
    final opened = await ref
        .read(driverContactControllerProvider)
        .openPassengerWhatsApp(ride);
    if (!context.mounted || opened) return;
    AppSnackBar.showError(
      context,
      'Impossible d\'ouvrir WhatsApp sans numéro passager valide.',
    );
  }

  bool _canOpenNavigation(DriverRide? ride) {
    if (ride == null) return false;
    final launcher = ref.read(driverNavigationLauncherProvider);
    final target = launcher.resolveDriverTarget(ride);
    return target.hasValidCoordinates;
  }

  Future<void> _openExternalNavigation(
    BuildContext context,
    DriverRide ride,
  ) async {
    if (_isNavigationLaunchInProgress) return;
    final launcher = ref.read(driverNavigationLauncherProvider);
    final target = launcher.resolveDriverTarget(ride);
    if (!target.hasValidCoordinates) {
      AppSnackBar.showError(
        context,
        'Coordonnées de navigation indisponibles pour cette course.',
      );
      return;
    }

    _isNavigationLaunchInProgress = true;
    try {
      final opened = await launcher.openGoogleMapsDriving(
        lat: target.latitude,
        lng: target.longitude,
        label: target.label,
      );
      if (!mounted) {
        _isNavigationLaunchInProgress = false;
        return;
      }
      if (!opened) {
        AppSnackBar.showError(
          this.context,
          'Impossible d\'ouvrir Google Maps sur cet appareil.',
        );
      }
    } finally {
      _isNavigationLaunchInProgress = false;
    }
  }

  Future<void> _showRideStatusPopup({
    required String title,
    required String message,
  }) async {
    if (!mounted || _isRideStatusDialogVisible) return;
    _isRideStatusDialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) {
          final hPad = dialogCtx.responsiveValue<double>(
            compact: 16,
            phone: 20,
            largePhone: 24,
            tablet: 32,
          );
          return FrayaDialog(
            padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FrayaDialogIcon(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: dialogCtx.textH2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: dialogCtx.textSmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 28),
                FrayaButton(
                  label: 'OK',
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      );
    } finally {
      _isRideStatusDialogVisible = false;
    }
  }

  Future<void> _showRideCancelledDialog(String message) async {
    if (!mounted || _isRideCancellationDialogVisible) return;
    _isRideCancellationDialogVisible = true;
    _playRideCancellationFeedback();
    try {
      await showRideCancelledAlertDialog(
        context,
        message: message,
        actionLabel: 'J\'ai compris',
      );
      _restoreRidePanelAfterCancellation();
    } finally {
      _isRideCancellationDialogVisible = false;
    }
  }

  void _playRideCancellationFeedback() {
    if (ref.read(driverSettingsProvider).soundsEnabled) {
      unawaited(_driverOfferSoundService.playRideCancelledAlert());
    }
    unawaited(HapticFeedback.heavyImpact());
  }

  Future<void> _requestPushPermissionOnce() async {
    final key = AppConstants.pushPermissionRequestedKey;
    if (LocalStorage.instance.getBool(key) == true) return;
    await LocalStorage.instance.setBool(key, true);
    unawaited(PushNotificationService.instance.requestPermission());
  }
}
