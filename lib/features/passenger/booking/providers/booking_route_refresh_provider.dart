import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class BookingOriginSnapshot {
  const BookingOriginSnapshot({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime capturedAt;
}

final bookingOriginSnapshotProvider =
    StateProvider<BookingOriginSnapshot?>((ref) => null);

final bookingManualRefreshTriggerProvider = StateProvider<int>((ref) => 0);

class BookingRouteRefreshController {
  const BookingRouteRefreshController(this._ref);

  final Ref _ref;

  void clearSnapshotAndRefresh() {
    _ref.read(bookingOriginSnapshotProvider.notifier).state = null;
    _ref.read(bookingManualRefreshTriggerProvider.notifier).state++;
  }
}

final bookingRouteRefreshControllerProvider = Provider(
  (ref) => BookingRouteRefreshController(ref),
);
