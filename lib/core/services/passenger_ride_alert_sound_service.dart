library;

import 'package:audioplayers/audioplayers.dart';

import '../utils/logger.dart';

class PassengerRideAlertSoundService {
  PassengerRideAlertSoundService({AudioPlayer? player})
    : _player = player ?? AudioPlayer(playerId: 'passenger_ride_alert');

  PassengerRideAlertSoundService.test() : _player = null;

  static final AssetSource _alertSource = AssetSource(
    'songs/mixkit-success-software-tone-2865.wav',
  );
  static final AssetSource _cancellationAlertSource = AssetSource(
    'songs/mixkit-double-beep-tone-alert-2868.wav',
  );

  final AudioPlayer? _player;

  Future<void> playAlert() => _play(_alertSource);

  Future<void> playCancellationAlert() => _play(_cancellationAlertSource);

  Future<void> _play(AssetSource source) async {
    final player = _player;
    if (player == null) return;
    try {
      await player.stop();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.release);
      await player.setVolume(1);
      await player.play(source);
    } catch (error, stackTrace) {
      logger.warning(
        'Lecture du son de statut passager impossible.',
        error,
        stackTrace,
      );
    }
  }

  Future<void> dispose() async {
    final player = _player;
    if (player == null) return;
    try {
      await player.dispose();
    } catch (_) {}
  }
}
