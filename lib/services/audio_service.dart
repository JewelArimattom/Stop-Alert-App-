import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  final AudioPlayer _alertPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Play a short alert sound
  Future<void> playAlertSound() async {
    try {
      await _alertPlayer.stop();
      await _alertPlayer.setSource(AssetSource('sounds/alert.wav'));
      await _alertPlayer.setVolume(0.8);
      await _alertPlayer.resume();
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Play continuous alarm sound (loops)
  Future<void> playAlarmSound() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.setSource(AssetSource('sounds/alarm.wav'));
      await _alarmPlayer.setVolume(1.0);
      await _alarmPlayer.resume();
    } catch (_) {
      _isPlaying = false;
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Stop all sounds
  Future<void> stop() async {
    _isPlaying = false;
    await _alertPlayer.stop();
    await _alarmPlayer.stop();
  }

  /// Stop only the looping alarm sound.
  Future<void> stopAlarm() async {
    _isPlaying = false;
    await _alarmPlayer.stop();
  }

  void dispose() {
    _alertPlayer.dispose();
    _alarmPlayer.dispose();
  }
}
