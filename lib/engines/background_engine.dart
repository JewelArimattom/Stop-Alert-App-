import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundEngine {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Initialize the background service
  static Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'stop_alert_tracking',
        initialNotificationTitle: '🚆 StopAlert',
        initialNotificationContent: 'Ready to track your destination',
        foregroundServiceNotificationId: 1,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  /// Start the background service
  static Future<void> start() async {
    await _service.startService();
  }

  /// Stop the background service
  static Future<void> stop() async {
    _service.invoke('stop');
  }

  /// Send data to background service
  static void sendData(Map<String, dynamic> data) {
    _service.invoke('update', data);
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stop').listen((event) {
      service.stopSelf();
    });

    service.on('update').listen((event) {
      if (event != null) {
        // Handle destination/tracking updates
      }
    });
  }
}
