import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../models/tracking_state.dart';
import '../utils/constants.dart';
import '../services/audio_service.dart';

class NotificationEngine {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioService _audioService = AudioService();
  AlertLevel _lastAlertLevel = AlertLevel.none;

  bool get isAlarmRinging => _audioService.isPlaying;

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    // Create notification channel for alerts
    const channel = AndroidNotificationChannel(
      'stop_alert_channel',
      'Stop Alert Notifications',
      description: 'Alerts when approaching destination',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    const trackingChannel = AndroidNotificationChannel(
      'stop_alert_tracking',
      'Tracking Service',
      description: 'Shows tracking status',
      importance: Importance.low,
    );
    await androidPlugin?.createNotificationChannel(trackingChannel);

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// Handle alert level changes and trigger appropriate notifications
  Future<void> handleAlertLevel(AlertLevel level, double distance) async {
    if (level == _lastAlertLevel) return;
    _lastAlertLevel = level;

    switch (level) {
      case AlertLevel.none:
        await cancelAll();
        break;
      case AlertLevel.notification:
        await _showNotification(
          'Getting Closer! 📍',
          'You are ${_formatDistance(distance)} from your destination',
        );
        break;
      case AlertLevel.sound:
        await _showNotification(
          'Almost There! ⚠️',
          'Only ${_formatDistance(distance)} left!',
        );
        await _audioService.playAlertSound();
        await _vibrate();
        break;
      case AlertLevel.alarm:
        await _showNotification(
          '🚨 WAKE UP! Your Stop is Here!',
          'You are ${_formatDistance(distance)} away - GET READY!',
        );
        await _audioService.playAlarmSound();
        await _vibratePattern();
        break;
    }
  }

  /// Show foreground service notification (for background tracking)
  Future<void> showTrackingNotification(
      String destination, double distance) async {
    const androidDetails = AndroidNotificationDetails(
      'stop_alert_tracking',
      'Tracking Service',
      channelDescription: 'Shows tracking status',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showWhen: false,
      category: AndroidNotificationCategory.service,
      icon: '@mipmap/ic_launcher',
    );
    try {
      await _notifications.show(
        NotificationIds.trackingService,
        '🚆 Tracking: $destination',
        '${_formatDistance(distance)} remaining',
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('NotificationEngine: tracking notification failed: $e');
    }
  }

  Future<void> triggerMilestoneAlarm({
    required String title,
    required String body,
    int notificationId = NotificationIds.alarmAlert,
  }) async {
    await _showNotification(
      title,
      body,
      notificationId: notificationId,
    );
    await _audioService.playAlarmSound();
    await _vibratePattern();
  }

  Future<void> showArrivalNotification({
    required String destinationName,
  }) async {
    await stopAlarmAudio();
    await _showNotification(
      'Arrived at $destinationName',
      'You reached your destination.',
      notificationId: NotificationIds.proximityAlert,
    );
    await _audioService.playAlertSound();
    await _vibrate();
  }

  Future<void> stopAlarmAudio() async {
    await _audioService.stopAlarm();
  }

  Future<void> _showNotification(
    String title,
    String body, {
    int notificationId = NotificationIds.proximityAlert,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'stop_alert_channel',
      'Stop Alert Notifications',
      channelDescription: 'Alerts when approaching destination',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      icon: '@mipmap/ic_launcher',
    );
    try {
      await _notifications.show(
        notificationId,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('NotificationEngine: notification failed: $e');
    }
  }

  Future<void> _vibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(duration: 500);
    }
  }

  Future<void> _vibratePattern() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 1000], intensities: [0, 255, 0, 255, 0, 255]);
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    await _audioService.stop();
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  void dispose() {
    _audioService.dispose();
  }
}
