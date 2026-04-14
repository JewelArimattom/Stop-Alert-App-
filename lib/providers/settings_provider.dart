import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  double _alertNotifyDistance = DistanceThresholds.alertNotify;
  double _alertSoundDistance = DistanceThresholds.alertSound;
  double _alertAlarmDistance = DistanceThresholds.alertAlarm;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;

  double get alertNotifyDistance => _alertNotifyDistance;
  double get alertSoundDistance => _alertSoundDistance;
  double get alertAlarmDistance => _alertAlarmDistance;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get soundEnabled => _soundEnabled;

  void load() {
    _alertNotifyDistance = StorageService.getAlertNotifyDistance();
    _alertSoundDistance = StorageService.getAlertSoundDistance();
    _alertAlarmDistance = StorageService.getAlertAlarmDistance();
    _vibrationEnabled = StorageService.getVibrationEnabled();
    _soundEnabled =
        StorageService.getSetting<bool>('soundEnabled') ?? true;
    notifyListeners();
  }

  Future<void> setAlertNotifyDistance(double value) async {
    _alertNotifyDistance = value;
    await StorageService.saveSetting('alertNotifyDistance', value);
    notifyListeners();
  }

  Future<void> setAlertSoundDistance(double value) async {
    _alertSoundDistance = value;
    await StorageService.saveSetting('alertSoundDistance', value);
    notifyListeners();
  }

  Future<void> setAlertAlarmDistance(double value) async {
    _alertAlarmDistance = value;
    await StorageService.saveSetting('alertAlarmDistance', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await StorageService.saveSetting('vibrationEnabled', value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await StorageService.saveSetting('soundEnabled', value);
    notifyListeners();
  }
}
