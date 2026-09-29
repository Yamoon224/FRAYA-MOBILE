import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/home_navigation_notifier.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../../../shared/providers/passenger_ride_alert_sound_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/confirmation_action_column.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../../../shared/widgets/fraya_dialog.dart';
import '../../../../shared/widgets/ride_cancelled_alert_dialog.dart';
import '../../settings/providers/passenger_settings_provider.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/booking_dependencies.dart'
    show
        bookingActiveRideCancelledHomeEventProvider,
        bookingErrorProvider,
        bookingRemoteRideCancelledEventProvider;
import '../providers/pending_search_session_provider.dart';
import '../providers/ride_categories_provider.dart';
import '../providers/route_directions_provider.dart';
import '../providers/booking_route_refresh_provider.dart';
import '../providers/selected_route_index_provider.dart';
import 'booking_error_modal.dart';

class BookingFlowListeners extends ConsumerStatefulWidget {
  const BookingFlowListeners({
    super.key,
    required this.child,
    required this.onNavigateToSearch,
    required this.onExpandSheet,
    this.onOpenDestinationSearch,
  });

  final Widget child;
  final VoidCallback onNavigateToSearch;
  final VoidCallback onExpandSheet;
  final VoidCallback? onOpenDestinationSearch;

  @override
  ConsumerState<BookingFlowListeners> createState() =>
      _BookingFlowListenersState();
}

class _BookingFlowListenersState extends ConsumerState<BookingFlowListeners> {
  bool _isCancellationDialogVisible = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedDestinationProvider, (previous, next) {
      if (next != null) widget.onExpandSheet();
      final changed =
          previous?.placeId != next?.placeId ||
          previous?.latitude != next?.latitude ||
          previous?.longitude != next?.longitude;
      final flowState = ref.read(bookingFlowProvider);
      if (changed && next != null && _isEditableBookingState(flowState)) {
        ref.read(selectedRouteIndexProvider.notifier).state = 0;
        ref
            .read(bookingRouteRefreshControllerProvider)
            .clearSnapshotAndRefresh();
      }
    });

    ref.listen(bookingFlowProvider, (previous, next) {
      if (next == BookingFlowState.activeRideConflict &&
          previous != BookingFlowState.activeRideConflict) {
        _showActiveRideConflictDialog(context, ref);
      }
    });

    ref.listen(pendingSearchTimeoutEventProvider, (previous, next) {
      if (next == previous || next == 0) return;
      _showPendingSearchTimeoutDialog(context, ref);
    });

    ref.listen(bookingActiveRideCancelledHomeEventProvider, (previous, next) {
      if (next == previous || next == 0) return;
      widget.onNavigateToSearch();
    });

    ref.listen(bookingRemoteRideCancelledEventProvider, (previous, next) {
      if (next == previous || next == 0) return;
      unawaited(_showRemoteRideCancellationDialog());
    });

    ref.listen(bookingErrorProvider, (_, error) {
      if (error == null) return;
      ref.read(bookingErrorProvider.notifier).state = null;
      final isSearchFailed =
          ref.read(bookingFlowProvider) == BookingFlowState.searchFailed;
      BookingErrorModal.show(
        context,
        message: error,
        onModifyDestination: widget.onNavigateToSearch,
        onRetry: isSearchFailed
            ? () => ref.read(bookingFlowProvider.notifier).retrySearching()
            : null,
      );
    });

    ref.listen(rideCategoriesProvider, (previous, next) {
      if (next is AsyncError && previous is! AsyncError) {
        BookingErrorModal.show(
          context,
          message: 'Impossible de charger les gammes de véhicules.',
          onModifyDestination: widget.onNavigateToSearch,
        );
      }
    });

    ref.listen(routeDirectionsProvider, (previous, next) {
      if (next is AsyncError && previous is! AsyncError) {
        BookingErrorModal.show(
          context,
          message:
              "Impossible de calculer l'itinéraire. Vérifiez votre connexion.",
          onModifyDestination: widget.onNavigateToSearch,
        );
      }
    });

    return widget.child;
  }

  Future<void> _showRemoteRideCancellationDialog() async {
    if (!mounted || _isCancellationDialogVisible) return;
    _isCancellationDialogVisible = true;
    _playCancellationFeedback();
    try {
      final action = await showRideCancelledAlertDialog(
        context,
        message: 'Votre chauffeur a annulé la course.',
        actionLabel: 'Rechercher un chauffeur',
        secondaryActionLabel: 'Revenir à l\'accueil',
      );
      if (!mounted) return;
      if (action == RideCancelledAlertAction.secondary) {
        widget.onNavigateToSearch();
        return;
      }
      (widget.onOpenDestinationSearch ?? widget.onNavigateToSearch)();
    } finally {
      _isCancellationDialogVisible = false;
    }
  }

  void _playCancellationFeedback() {
    final settings = ref.read(passengerSettingsProvider);
    if (settings.soundsEnabled) {
      unawaited(
        ref
            .read(passengerRideAlertSoundServiceProvider)
            .playCancellationAlert(),
      );
    }
    unawaited(HapticFeedback.heavyImpact());
  }

  void _showActiveRideConflictDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final hPad = ctx.responsiveValue<double>(
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
                icon: Icons.directions_car_outlined,
                color: AppColors.warning,
              ),
              const SizedBox(height: 20),
              Text(
                'Course en cours',
                textAlign: TextAlign.center,
                style: ctx.textH2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Vous avez déjà une course en cours.\n'
                "Souhaitez-vous l'annuler pour en démarrer une nouvelle ?",
                textAlign: TextAlign.center,
                style: ctx.textSmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              ConfirmationActionColumn(
                primaryLabel: 'Annuler et continuer',
                primaryVariant: FrayaButtonVariant.danger,
                onPrimaryPressed: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(bookingFlowProvider.notifier)
                      .cancelExistingAndRetry();
                },
                secondaryLabel: 'Garder ma course',
                onSecondaryPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(bookingFlowProvider.notifier).reset();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  void _showPendingSearchTimeoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final hPad = ctx.responsiveValue<double>(
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
                icon: Icons.search_off_rounded,
                color: AppColors.info,
              ),
              const SizedBox(height: 20),
              Text(
                'Recherche interrompue',
                textAlign: TextAlign.center,
                style: ctx.textH2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Aucun chauffeur disponible pour le moment. '
                'Voulez-vous continuer la recherche ou modifier votre destination ?',
                textAlign: TextAlign.center,
                style: ctx.textSmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              ConfirmationActionColumn(
                primaryLabel: 'Modifier ma destination',
                onPrimaryPressed: () {
                  Navigator.of(ctx).pop();
                  HomeNavigationNotifier.instance.requestResetSearchState();
                  HomeNavigationNotifier.instance
                      .requestOpenDestinationSearchOnHome();
                  context.go(RoutePaths.passengerHome);
                },
                secondaryLabel: 'Continuer la recherche',
                onSecondaryPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(bookingFlowProvider.notifier).startSearching();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  bool _isEditableBookingState(BookingFlowState state) {
    return state == BookingFlowState.idle ||
        state == BookingFlowState.routePreview ||
        state == BookingFlowState.searching ||
        state == BookingFlowState.searchFailed;
  }
}
