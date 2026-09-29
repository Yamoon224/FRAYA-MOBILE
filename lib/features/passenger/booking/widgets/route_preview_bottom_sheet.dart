import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/models/places_models.dart';
import '../../../../core/models/ride_category.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/ride_status.dart';
import '../models/booking_flow_state.dart';
import '../providers/payment_method_provider.dart';
import 'active_ride_sheet.dart';
import 'booking_details_sheet.dart';
import 'searching_driver_sheet.dart';

class RoutePreviewBottomSheet extends StatelessWidget {
  const RoutePreviewBottomSheet({
    super.key,
    required this.controller,
    required this.flowState,
    required this.activeRideStatus,
    required this.directionsAsync,
    required this.destination,
    required this.categories,
    required this.selectedCategory,
    required this.selectedPaymentMethod,
    required this.onCategorySelected,
    required this.onPaymentMethodSelected,
    required this.onRefreshRoutePricing,
    required this.onRefreshRideStatus,
    required this.onEditPickup,
    required this.onEditDestination,
    required this.onConfirmBooking,
  });

  final DraggableScrollableController controller;
  final BookingFlowState flowState;
  final RideStatus? activeRideStatus;
  final AsyncValue<DirectionsResult?> directionsAsync;
  final PlaceDetails? destination;
  final AsyncValue<List<RideCategory>> categories;
  final RideCategory? selectedCategory;
  final PaymentMethod selectedPaymentMethod;
  final ValueChanged<RideCategory> onCategorySelected;
  final ValueChanged<PaymentMethod> onPaymentMethodSelected;
  final Future<void> Function() onRefreshRoutePricing;
  final Future<void> Function() onRefreshRideStatus;
  final VoidCallback onEditPickup;
  final VoidCallback onEditDestination;
  final VoidCallback onConfirmBooking;

  @override
  Widget build(BuildContext context) {
    if (flowState == BookingFlowState.searching) {
      final searchingDefaultSize = context.responsiveValue<double>(
        compact: 0.50,
        phone: 0.46,
        largePhone: 0.44,
        tablet: 0.40,
      );
      final searchingMinSize = context.responsiveValue<double>(
        compact: 0.22,
        phone: 0.22,
        largePhone: 0.20,
        tablet: 0.18,
      );
      return DraggableScrollableSheet(
        initialChildSize: searchingDefaultSize,
        minChildSize: searchingMinSize,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: [searchingDefaultSize],
        builder: (context, scrollController) => SearchingDriverSheet(
          scrollController: scrollController,
          onRefresh: onRefreshRideStatus,
        ),
      );
    }

    final isActiveRideSheet =
        flowState == BookingFlowState.driverAssigned ||
        flowState == BookingFlowState.arrived ||
        flowState == BookingFlowState.inProgress;
    final activeRideDefaultSize = context.responsiveValue<double>(
      compact: 0.52,
      phone: 0.48,
      largePhone: 0.46,
      tablet: 0.42,
    );
    final bookingSheetDefaultSize = context.responsiveValue<double>(
      compact: 0.62,
      phone: 0.58,
      largePhone: 0.55,
      tablet: 0.50,
    );
    final sheetMinSize = context.responsiveValue<double>(
      compact: 0.22,
      phone: 0.22,
      largePhone: 0.20,
      tablet: 0.18,
    );
    final initialChildSize =
        isActiveRideSheet ? activeRideDefaultSize : bookingSheetDefaultSize;
    final snapSizes = isActiveRideSheet
        ? <double>[activeRideDefaultSize]
        : <double>[bookingSheetDefaultSize];

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: initialChildSize,
      minChildSize: sheetMinSize,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: snapSizes,
      builder: (context, scrollController) {
        if (flowState == BookingFlowState.driverAssigned ||
            flowState == BookingFlowState.arrived ||
            flowState == BookingFlowState.inProgress) {
          return ActiveRideSheet(
            scrollController: scrollController,
            onRefresh: onRefreshRideStatus,
          );
        }
        return BookingDetailsSheet(
          scrollController: scrollController,
          directionsAsync: directionsAsync,
          destination: destination,
          categories: categories,
          selectedCategory: selectedCategory,
          selectedPaymentMethod: selectedPaymentMethod,
          onCategorySelected: onCategorySelected,
          onPaymentMethodSelected: onPaymentMethodSelected,
          onRefreshRoutePricing: onRefreshRoutePricing,
          onEditPickup: onEditPickup,
          onEditDestination: onEditDestination,
          onConfirm: onConfirmBooking,
        );
      },
    );
  }
}
