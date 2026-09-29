import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/providers/map_icons_provider.dart';
import 'package:fraya_mobile/shared/widgets/map/fraya_map_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, Object?> expectSizedBitmap(
    BitmapDescriptor descriptor, {
    required double width,
    required double height,
  }) {
    final json = descriptor.toJson();
    expect(json, isA<List<Object?>>());

    final payload = (json as List<Object?>)[1];
    expect(payload, isA<Map<String, Object?>>());

    final data = payload as Map<String, Object?>;
    expect(data['width'], width);
    expect(data['height'], height);
    return data;
  }

  testWidgets('builds compact shared pin markers for map flows', (
    tester,
  ) async {
    expect(compactDriverCarMarkerLogicalSize, 17.0);
    expect(compactDriverCarMarkerLogicalWidth, 17.0);
    expect(compactDriverCarMarkerLogicalHeight, 34.0);
    expect(compactUserMarkerLogicalSize, 22.0);
    expect(compactRoutePinMarkerLogicalSize, 20.0);
    expect(pickupMarkerLogicalWidth, 16.0);
    expect(pickupMarkerLogicalHeight, 32.0);
    expect(destinationMarkerLogicalWidth, 19.0);
    expect(destinationMarkerLogicalHeight, 25.0);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final markers = await tester.runAsync(() async {
      final user = await container.read(userIconProvider.future);
      final green = await container.read(
        compactPinMarkerIconProvider(CompactMapPinColor.green).future,
      );
      final red = await container.read(
        compactPinMarkerIconProvider(CompactMapPinColor.red).future,
      );
      final orange = await container.read(
        compactPinMarkerIconProvider(CompactMapPinColor.orange).future,
      );
      final driver = await container.read(
        driverCarMarkerIconProvider(const Color(0xFFD4A843)).future,
      );
      final pickup = await container.read(pickupMarkerIconProvider.future);
      final destination = await container.read(
        destinationMarkerIconProvider.future,
      );
      return [user, green, red, orange, driver, pickup, destination];
    });

    expect(markers, isNotNull);
    expect(markers![0], isA<BitmapDescriptor>());
    expect(markers[1], isA<BitmapDescriptor>());
    expect(markers[2], isA<BitmapDescriptor>());
    expect(markers[3], isA<BitmapDescriptor>());
    expect(markers[4], isA<BitmapDescriptor>());
    expect(markers[5], isA<BitmapDescriptor>());
    expect(markers[6], isA<BitmapDescriptor>());

    final userData = expectSizedBitmap(
      markers[0]!,
      width: compactUserMarkerLogicalSize,
      height: compactUserMarkerLogicalSize,
    );
    final greenData = expectSizedBitmap(
      markers[1]!,
      width: compactRoutePinMarkerLogicalSize,
      height: compactRoutePinMarkerLogicalSize,
    );
    final driverData = expectSizedBitmap(
      markers[4]!,
      width: compactDriverCarMarkerLogicalWidth,
      height: compactDriverCarMarkerLogicalHeight,
    );
    final pickupData = expectSizedBitmap(
      markers[5]!,
      width: pickupMarkerLogicalWidth,
      height: pickupMarkerLogicalHeight,
    );
    final destinationData = expectSizedBitmap(
      markers[6]!,
      width: destinationMarkerLogicalWidth,
      height: destinationMarkerLogicalHeight,
    );

    expect(userData['bitmapScaling'], 'auto');
    expect(greenData['bitmapScaling'], 'auto');
    expect(driverData['bitmapScaling'], 'auto');
    expect(pickupData['bitmapScaling'], 'auto');
    expect(destinationData['bitmapScaling'], 'auto');
  });

  test('uses a shared map style that keeps Google POI markers visible', () {
    expect(frayaMapDefaultStyle, contains('"featureType": "poi"'));
    expect(frayaMapDefaultStyle, contains('"visibility": "on"'));
  });
}
