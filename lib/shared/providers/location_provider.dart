import 'package:flutter_riverpod/flutter_riverpod.dart'
    show FutureProvider, Provider;
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/address_formatter_service.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/services/location_service.dart';

part 'location_provider.g.dart';

enum PassengerLocationReadiness { loading, ready, unavailable }

final locationTrackingRequestCountProvider = StateProvider<int>((ref) => 0);
final passengerLocationSnapshotRefreshTriggerProvider = StateProvider<int>(
  (ref) => 0,
);

const _emptyAddress = <String, String>{'commune': '', 'quartier': ''};

@riverpod
LocationService locationService(Ref ref) {
  return LocationService();
}

@riverpod
GeocodingService geocodingService(Ref ref) {
  return GeocodingService();
}

Future<Position?> _readSinglePosition(LocationService service) async {
  final lastKnownPosition = await service.getLastKnownPosition();
  if (lastKnownPosition != null) {
    return lastKnownPosition;
  }
  return service.getCurrentPosition();
}

String _formatResolvedAddress(Map<String, String> address) {
  const formatter = AddressFormatterService();
  final formatted = formatter.normalize(address['formatted'] ?? '');
  if (formatted.isNotEmpty) return formatted;

  final commune = address['commune'] ?? '';
  final quartier = address['quartier'] ?? '';
  if (commune.isEmpty && quartier.isEmpty) return 'Position inconnue';

  return formatter.format(
    formatter.fromComponents(quarter: quartier, commune: commune),
  );
}

final passengerLocationSnapshotProvider = FutureProvider<Position?>((
  ref,
) async {
  ref.watch(passengerLocationSnapshotRefreshTriggerProvider);
  final service = ref.watch(locationServiceProvider);
  return _readSinglePosition(service);
});

final passengerLocationReadinessProvider = Provider<PassengerLocationReadiness>(
  (ref) {
    final snapshot = ref.watch(passengerLocationSnapshotProvider);
    return snapshot.when(
      data: (position) => position == null
          ? PassengerLocationReadiness.unavailable
          : PassengerLocationReadiness.ready,
      loading: () => PassengerLocationReadiness.loading,
      error: (_, _) => PassengerLocationReadiness.unavailable,
    );
  },
);

String passengerLocationBlockingMessage(PassengerLocationReadiness readiness) {
  return switch (readiness) {
    PassengerLocationReadiness.loading =>
      'Position en cours de récupération. Réessayez dans un instant.',
    PassengerLocationReadiness.unavailable =>
      'Impossible de récupérer votre position. Activez le GPS puis réessayez.',
    PassengerLocationReadiness.ready => '',
  };
}

final passengerUserAddressProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final position = await ref.watch(passengerLocationSnapshotProvider.future);
  if (position == null) return _emptyAddress;

  final geocoding = ref.read(geocodingServiceProvider);
  return geocoding.reverseGeocode(position.latitude, position.longitude);
});

final passengerFormattedAddressProvider = Provider<String>((ref) {
  final addressAsync = ref.watch(passengerUserAddressProvider);

  return addressAsync.when(
    data: _formatResolvedAddress,
    loading: () => 'Recherche...',
    error: (_, _) => 'Erreur adresse',
  );
});

@riverpod
Stream<Position?> currentLocation(Ref ref) async* {
  final isTrackingEnabled = ref.watch(locationTrackingRequestCountProvider) > 0;
  if (!isTrackingEnabled) {
    yield null;
    return;
  }

  final service = ref.watch(locationServiceProvider);

  // First one-shot read, then keep the stream alive for updates.
  final initialPosition = await _readSinglePosition(service);
  if (initialPosition != null) {
    yield initialPosition;
  }

  yield* service.getPositionStream().map<Position?>((position) => position);
}

@riverpod
Future<Map<String, String>> userAddress(Ref ref) async {
  final position = await ref.watch(currentLocationProvider.future);
  if (position == null) return _emptyAddress;

  final geocoding = ref.read(geocodingServiceProvider);
  return geocoding.reverseGeocode(position.latitude, position.longitude);
}

@riverpod
String formattedAddress(Ref ref) {
  final addressAsync = ref.watch(userAddressProvider);

  return addressAsync.when(
    data: _formatResolvedAddress,
    loading: () => 'Recherche...',
    error: (_, _) => 'Erreur adresse',
  );
}
