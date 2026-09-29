import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/places_provider.dart';

final homeSearchStateControllerProvider = Provider<HomeSearchStateController>(
  (ref) => HomeSearchStateController(ref),
);

class HomeSearchStateController {
  const HomeSearchStateController(this._ref);

  final Ref _ref;

  void resetAfterBookingReturn() {
    _ref.read(selectedDestinationProvider.notifier).clear();
    _ref.read(selectedPickupProvider.notifier).clear();
    _ref.read(searchQueryProvider.notifier).clear();
    _ref
        .read(activeSearchTypeProvider.notifier)
        .setType(SearchType.destination);
  }
}
