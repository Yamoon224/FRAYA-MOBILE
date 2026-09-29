library;

import 'package:audioplayers/audioplayers.dart';

class DriverOfferSoundService {
  DriverOfferSoundService({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  static const String incomingRideAlertAssetPath =
      'songs/universfield-ringtone-021-365652.mp3';
  static final AssetSource _incomingRideAlertSource = AssetSource(
    incomingRideAlertAssetPath,
  );
  static final AssetSource _rideCancelledAlertSource = AssetSource(
    'songs/mixkit-double-beep-tone-alert-2868.wav',
  );

  final AudioPlayer _player;
  bool _isPlayingIncomingRideAlert = false;

  Future<void> playIncomingRideAlert() async {
    if (_isPlayingIncomingRideAlert) return;

    _isPlayingIncomingRideAlert = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(_incomingRideAlertSource);
    } catch (_) {
      _isPlayingIncomingRideAlert = false;
    }
  }

  Future<void> stopIncomingRideAlert() async {
    _isPlayingIncomingRideAlert = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> playRideCancelledAlert() async {
    _isPlayingIncomingRideAlert = false;
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(_rideCancelledAlertSource);
    } catch (_) {}
  }

  Future<void> dispose() async {
    _isPlayingIncomingRideAlert = false;
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
