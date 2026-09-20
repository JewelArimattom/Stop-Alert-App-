import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  final AudioPlayer _alertPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _customAlarmPath;

  bool get isPlaying => _isPlaying;

  /// Set a custom alarm file path
  void setCustomAlarmPath(String? path) {
    _customAlarmPath = path;
  }

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

  /// Play continuous alarm sound (loops) — uses custom path if set
  Future<void> playAlarmSound() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);

      if (_customAlarmPath != null && File(_customAlarmPath!).existsSync()) {
        await _alarmPlayer.setSource(DeviceFileSource(_customAlarmPath!));
      } else {
        await _alarmPlayer.setSource(AssetSource('sounds/alarm.wav'));
      }

      await _alarmPlayer.setVolume(1.0);
      await _alarmPlayer.resume();
    } catch (_) {
      _isPlaying = false;
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Preview an alarm sound (for settings screen)
  Future<void> playPreview(String? path) async {
    await _previewPlayer.stop();
    try {
      if (path != null && File(path).existsSync()) {
        await _previewPlayer.setSource(DeviceFileSource(path));
      } else {
        await _previewPlayer.setSource(AssetSource('sounds/alarm.wav'));
      }
      await _previewPlayer.setVolume(1.0);
      await _previewPlayer.resume();
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Stop preview playback
  Future<void> stopPreview() async {
    await _previewPlayer.stop();
  }

  /// Stop all sounds
  Future<void> stop() async {
    _isPlaying = false;
    await _alertPlayer.stop();
    await _alarmPlayer.stop();
    await _previewPlayer.stop();
  }

  /// Stop only the looping alarm sound.
  Future<void> stopAlarm() async {
    _isPlaying = false;
    await _alarmPlayer.stop();
  }

  void dispose() {
    _alertPlayer.dispose();
    _alarmPlayer.dispose();
    _previewPlayer.dispose();
  }
}
