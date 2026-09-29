import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/shared/providers/map_icons_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void expectSizedBitmap(
    BitmapDescriptor descriptor, {
    required double width,
    required double height,
  }) {
    final json = descriptor.toJson() as List<Object?>;
    final data = json[1] as Map<String, Object?>;

    expect(data['width'], width);
    expect(data['height'], height);
  }

  group('driverCarSvgIconProvider', () {
    test('returns cached descriptor for same color key', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = await container.read(
        driverCarSvgIconProvider('Rouge').future,
      );
      final second = await container.read(
        driverCarSvgIconProvider('Rouge').future,
      );

      expect(identical(first, second), isTrue);
    });

    test('falls back safely when color is missing or invalid', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final fromNull = await container.read(
        driverCarSvgIconProvider(null).future,
      );
      final fromInvalid = await container.read(
        driverCarSvgIconProvider('not-a-real-color').future,
      );

      expect(fromNull, isNotNull);
      expect(fromInvalid, isNotNull);
    });

    test('builds a non-square Fraya car marker', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final marker = await container.read(
        driverCarSvgIconProvider('#1976D2').future,
      );

      expectSizedBitmap(
        marker,
        width: compactDriverCarMarkerLogicalWidth,
        height: compactDriverCarMarkerLogicalHeight,
      );
    });
  });

  group('route marker providers', () {
    test(
      'build Fraya pickup and destination markers with expected sizes',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final pickup = await container.read(pickupMarkerIconProvider.future);
        final destination = await container.read(
          destinationMarkerIconProvider.future,
        );

        expect(pickup, isNotNull);
        expect(destination, isNotNull);
        expectSizedBitmap(
          pickup!,
          width: pickupMarkerLogicalWidth,
          height: pickupMarkerLogicalHeight,
        );
        expectSizedBitmap(
          destination!,
          width: destinationMarkerLogicalWidth,
          height: destinationMarkerLogicalHeight,
        );
      },
    );
  });
}
