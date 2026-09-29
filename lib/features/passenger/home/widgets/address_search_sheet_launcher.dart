import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import '../providers/address_search_sheet_focus_controller.dart';
import 'destination_search_sheet.dart';

Future<void> showPassengerAddressSearchSheet(
  BuildContext context,
  WidgetRef ref, {
  SearchType initialType = SearchType.destination,
}) async {
  ref.read(activeSearchTypeProvider.notifier).setType(initialType);
  ref
      .read(addressSearchSheetFocusControllerProvider.notifier)
      .requestFocus(initialType);
  ref.read(searchQueryProvider.notifier).clear();
  ref.read(passengerLocationSnapshotRefreshTriggerProvider.notifier).state++;
  unawaited(ref.read(passengerUserAddressProvider.future));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const DestinationSearchSheet(),
  );
}
