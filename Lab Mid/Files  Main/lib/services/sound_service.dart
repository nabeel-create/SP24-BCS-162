import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playClick() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/click.wav'), volume: 1.0);
    } catch (_) {}
  }
}
