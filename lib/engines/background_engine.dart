import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../engines/distance_engine.dart';
import '../engines/notification_engine.dart';
import '../models/tracking_state.dart';
import '../models/trip.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

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

  /// Stop any alarm audio in the background isolate
  static Future<void> stopAlarm() async {
    _service.invoke('stopAlarm');
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

    await StorageService.initialize();
    final tracker = _BackgroundTracker(service);
    await tracker.initialize();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    final Trip? activeTrip = StorageService.getActiveTrip();
    if (activeTrip != null) {
      await tracker.updateDestination(
        destinationName: activeTrip.destinationName,
        destLatitude: activeTrip.destLatitude,
        destLongitude: activeTrip.destLongitude,
      );
    }

    service.on('stop').listen((event) async {
      await tracker.stop();
      service.stopSelf();
    });

    service.on('stopAlarm').listen((event) async {
      await tracker.stopAlarm();
    });

    service.on('update').listen((event) async {
      if (event is! Map) return;
      final data = Map<String, dynamic>.from(event as Map);
      final destinationName = data['destinationName']?.toString() ?? '';
      final destLatitude = _parseDouble(data['destLatitude']);
      final destLongitude = _parseDouble(data['destLongitude']);
      if (destinationName.isEmpty || destLatitude == null || destLongitude == null) {
        return;
      }
      await tracker.updateDestination(
        destinationName: destinationName,
        destLatitude: destLatitude,
        destLongitude: destLongitude,
      );
    });
  }
}

class _BackgroundTracker {
  final ServiceInstance _service;
  final NotificationEngine _notificationEngine = NotificationEngine();

  Timer? _timer;
  LatLng? _destination;
  String _destinationName = '';
  TrackingZone _zone = TrackingZone.far;
  bool _triggeredOneKmAlarm = false;
  bool _triggeredThreeHundredAlarm = false;
  bool _triggeredArrivalNotice = false;
  bool _isTickRunning = false;

  _BackgroundTracker(this._service);

  Future<void> initialize() async {
    await _notificationEngine.initialize(requestPermissions: false);
  }

  Future<void> updateDestination({
    required String destinationName,
    required double destLatitude,
    required double destLongitude,
  }) async {
    _destinationName = destinationName;
    _destination = LatLng(destLatitude, destLongitude);
    _zone = TrackingZone.far;
    _resetMilestones();
    _restartTimer();
    await _tick();
  }

  Future<void> stopAlarm() async {
    await _notificationEngine.stopAlarmAudio();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _destination = null;
    _destinationName = '';
    _zone = TrackingZone.far;
    _resetMilestones();
    await _notificationEngine.cancelAll();
  }

  Future<void> _tick() async {
    if (_isTickRunning || _destination == null) return;
    _isTickRunning = true;
    try {
      final hasPermission = await _hasLocationPermission();
      if (!hasPermission) return;

      final position = await _getPosition();
      if (position == null) return;

      final current = LatLng(position.latitude, position.longitude);
      final distance = DistanceEngine.calculateDistance(current, _destination!);
      final zone = DistanceEngine.determineZone(distance);

      if (zone != _zone) {
        _zone = zone;
        _restartTimer();
      }

      await _updateForegroundNotification(distance);
      await _handleMilestones(distance);
    } catch (e) {
      debugPrint('BackgroundTracker: tick failed: $e');
    } finally {
      _isTickRunning = false;
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    final intervalSeconds = _intervalForZone(_zone);
    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _tick(),
    );
  }

  Future<void> _updateForegroundNotification(double distance) async {
    if (_destinationName.isEmpty) return;
    if (_service is AndroidServiceInstance) {
      final androidService = _service as AndroidServiceInstance;
      await androidService.setForegroundNotificationInfo(
        title: '🚆 Tracking: $_destinationName',
        content: '${_formatDistance(distance)} remaining',
      );
    }
  }

  Future<void> _handleMilestones(double distanceMeters) async {
    if (_destination == null) return;

    if (!_triggeredOneKmAlarm && distanceMeters <= 1000) {
      _triggeredOneKmAlarm = true;
      await _notificationEngine.triggerMilestoneAlarm(
        title: '1 km remaining',
        body: 'Only ${distanceMeters.toInt()} m to $_destinationName.',
        notificationId: NotificationIds.soundAlert,
      );
    }

    if (!_triggeredThreeHundredAlarm && distanceMeters <= 300) {
      _triggeredThreeHundredAlarm = true;
      await _notificationEngine.triggerMilestoneAlarm(
        title: '300 m remaining',
        body: 'Very close to $_destinationName.',
        notificationId: NotificationIds.alarmAlert,
      );
    }

    if (!_triggeredArrivalNotice && distanceMeters <= DistanceThresholds.veryClose) {
      _triggeredArrivalNotice = true;
      await _notificationEngine.showArrivalNotification(
        destinationName: _destinationName,
      );
    }
  }

  Future<bool> _hasLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracyForZone(_zone),
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  int _intervalForZone(TrackingZone zone) {
    switch (zone) {
      case TrackingZone.far:
        return TrackingIntervals.far;
      case TrackingZone.mid:
        return TrackingIntervals.mid;
      case TrackingZone.near:
        return TrackingIntervals.near;
      case TrackingZone.veryClose:
      case TrackingZone.arrived:
        return TrackingIntervals.veryClose;
    }
  }

  LocationAccuracy _accuracyForZone(TrackingZone zone) {
    switch (zone) {
      case TrackingZone.far:
        return LocationAccuracy.high;
      case TrackingZone.mid:
        return LocationAccuracy.high;
      case TrackingZone.near:
        return LocationAccuracy.best;
      case TrackingZone.veryClose:
      case TrackingZone.arrived:
        return LocationAccuracy.best;
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  void _resetMilestones() {
    _triggeredOneKmAlarm = false;
    _triggeredThreeHundredAlarm = false;
    _triggeredArrivalNotice = false;
  }
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  return double.tryParse(value.toString());
}
