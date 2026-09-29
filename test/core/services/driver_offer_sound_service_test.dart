import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/driver_offer_sound_service.dart';

void main() {
  test('uses the configured incoming ride alert asset', () {
    expect(
      DriverOfferSoundService.incomingRideAlertAssetPath,
      'songs/universfield-ringtone-021-365652.mp3',
    );
  });
}
