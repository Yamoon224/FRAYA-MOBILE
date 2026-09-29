import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/features/passenger/home/providers/address_search_sheet_focus_controller.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

void main() {
  test('requestFocus publishes unique request ids and latest target', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(
      addressSearchSheetFocusControllerProvider.notifier,
    );

    notifier.requestFocus(SearchType.pickup);
    final pickupRequest = container.read(
      addressSearchSheetFocusControllerProvider,
    );

    notifier.requestFocus(SearchType.destination);
    final destinationRequest = container.read(
      addressSearchSheetFocusControllerProvider,
    );

    expect(pickupRequest, isNotNull);
    expect(destinationRequest, isNotNull);
    expect(pickupRequest!.target, SearchType.pickup);
    expect(destinationRequest!.target, SearchType.destination);
    expect(destinationRequest.requestId, greaterThan(pickupRequest.requestId));
    expect(destinationRequest.selectAllOnFocus, isTrue);
  });
}
