import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/address_formatter_service.dart';
import 'package:fraya_mobile/core/services/home_navigation_notifier.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_provider.dart';
import 'package:fraya_mobile/shared/providers/recent_places_provider.dart';
import 'package:fraya_mobile/shared/widgets/app_snack_bar.dart';
import 'package:fraya_mobile/shared/widgets/confirmation_action_column.dart';
import 'package:fraya_mobile/shared/widgets/fraya_button.dart';
import '../../../../shared/providers/places_provider.dart';

final homeDestinationIntentControllerProvider =
    Provider<HomeDestinationIntentController>(
      (ref) => HomeDestinationIntentController(ref),
    );

enum DestinationConflictDecision { continueCurrentSearch, cancelAndContinue }

class HomeDestinationIntentController {
  const HomeDestinationIntentController(this._ref);

  final Ref _ref;
  static const _addressFormatter = AddressFormatterService();

  Future<void> handleResolvedDestination({
    required BuildContext context,
    required PlaceDetails destination,
    required bool closeSearchSheet,
    bool addToRecent = true,
  }) async {
    final flowState = _ref.read(bookingFlowProvider);
    if (_hasActiveRideInProgress(flowState)) {
      AppSnackBar.showInfo(
        context,
        'Vous avez d\u00E9j\u00E0 une course en cours.',
      );
      _closeSearchSheetIfNeeded(context, closeSearchSheet);
      return;
    }
    if (flowState != BookingFlowState.searching) {
      _applyDestination(destination, addToRecent: addToRecent);
      _closeSearchSheetIfNeeded(context, closeSearchSheet);
      if (flowState != BookingFlowState.idle) {
        HomeNavigationNotifier.instance.requestOpenVehicleSelection();
      }
      return;
    }

    final decision = await _showSearchConflictDialog(context);
    if (!context.mounted) return;
    if (decision == null) return;

    if (decision == DestinationConflictDecision.continueCurrentSearch) {
      _closeSearchSheetIfNeeded(context, closeSearchSheet);
      HomeNavigationNotifier.instance.requestOpenVehicleSelection();
      return;
    }

    await _ref
        .read(bookingFlowProvider.notifier)
        .cancelSearching(reason: 'Nouvelle destination');
    if (!context.mounted) return;
    final updatedFlow = _ref.read(bookingFlowProvider);
    if (updatedFlow == BookingFlowState.routePreview) {
      _applyDestination(destination, addToRecent: addToRecent);
      _closeSearchSheetIfNeeded(context, closeSearchSheet);
      HomeNavigationNotifier.instance.requestOpenVehicleSelection();
      return;
    }

    final currentError = _ref.read(bookingErrorProvider);
    if (currentError == null || currentError.isEmpty) {
      _ref.read(bookingErrorProvider.notifier).state =
          "Impossible d'annuler la recherche en cours pour le moment.";
    }
    _closeSearchSheetIfNeeded(context, closeSearchSheet);
    HomeNavigationNotifier.instance.requestOpenVehicleSelection();
  }

  void _applyDestination(
    PlaceDetails destination, {
    required bool addToRecent,
  }) {
    final normalized = destination.copyWith(
      address: _addressFormatter.normalize(destination.address),
    );
    _ref.read(selectedDestinationProvider.notifier).setPlace(normalized);
    if (addToRecent) {
      _ref.read(recentPlacesProvider.notifier).add(normalized);
    }
  }

  void _closeSearchSheetIfNeeded(BuildContext context, bool closeSearchSheet) {
    if (!closeSearchSheet) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<DestinationConflictDecision?> _showSearchConflictDialog(
    BuildContext context,
  ) {
    return showDialog<DestinationConflictDecision>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Recherche en cours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Vous avez déjà une recherche de chauffeur en cours. '
                'Voulez-vous la continuer ou l\'annuler pour démarrer un nouveau trajet ?',
              ),
              const SizedBox(height: 20),
              ConfirmationActionColumn(
                primaryLabel: 'Annuler et continuer',
                primaryVariant: FrayaButtonVariant.danger,
                onPrimaryPressed: () {
                  Navigator.of(
                    ctx,
                  ).pop(DestinationConflictDecision.cancelAndContinue);
                },
                secondaryLabel: 'Continuer',
                onSecondaryPressed: () {
                  Navigator.of(
                    ctx,
                  ).pop(DestinationConflictDecision.continueCurrentSearch);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasActiveRideInProgress(BookingFlowState flowState) {
    if (_isActiveRideFlowState(flowState)) return true;
    if (_isActiveRide(_ref.read(activeRideControllerProvider))) return true;
    return _isActiveRide(_ref.read(activeRideCheckProvider).asData?.value);
  }

  bool _isActiveRideFlowState(BookingFlowState flowState) {
    return flowState == BookingFlowState.driverAssigned ||
        flowState == BookingFlowState.arrived ||
        flowState == BookingFlowState.inProgress;
  }

  bool _isActiveRide(ActiveRide? ride) {
    return ride != null &&
        (ride.status == RideStatus.accepted ||
            ride.status == RideStatus.arrived ||
            ride.status == RideStatus.inProgress);
  }
}
