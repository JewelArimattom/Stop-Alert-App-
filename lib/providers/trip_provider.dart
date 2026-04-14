import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/destination.dart';
import '../models/trip.dart';
import '../models/tracking_state.dart';
import '../engines/location_engine.dart';
import '../engines/distance_engine.dart';
import '../engines/geofence_engine.dart';
import '../engines/travel_detection_engine.dart';
import '../engines/notification_engine.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class TripProvider extends ChangeNotifier {
  final LocationEngine _locationEngine = LocationEngine();
  final GeofenceEngine _geofenceEngine = GeofenceEngine();
  final TravelDetectionEngine _travelDetectionEngine =
      TravelDetectionEngine();
  final NotificationEngine _notificationEngine = NotificationEngine();
  final _uuid = const Uuid();

  Trip? _activeTrip;
  TrackingData _trackingData = const TrackingData();
  List<Trip> _tripHistory = [];
  bool _isAlarmRinging = false;

  bool _triggeredOneKmAlarm = false;
  bool _triggeredThreeHundredAlarm = false;
  bool _triggeredArrivalNotice = false;

  StreamSubscription<LatLng>? _positionSub;
  StreamSubscription<double>? _speedSub;

  // Getters
  Trip? get activeTrip => _activeTrip;
  TrackingData get trackingData => _trackingData;
  bool get isAlarmRinging => _isAlarmRinging;
  List<Trip> get tripHistory {
    if (_activeTrip == null) return _tripHistory;
    final hasActiveInHistory =
        _tripHistory.any((trip) => trip.id == _activeTrip!.id);
    if (hasActiveInHistory) return _tripHistory;
    return [_activeTrip!, ..._tripHistory];
  }
  bool get isTracking => _activeTrip != null;

  Future<void> initialize() async {
    await _notificationEngine.initialize();
    _loadData();
  }

  void _loadData() {
    _tripHistory = StorageService.getTrips();
    _activeTrip = StorageService.getActiveTrip();
    _resetAlertMilestones();

    if (_activeTrip != null) {
      // Resume tracking if there's an active trip
      _startTrackingInternal();
    }

    notifyListeners();
  }

  // ─── Destination Management ───────────────────────────────────

  // ─── Trip Management ──────────────────────────────────────────

  Future<bool> startTrip(Destination destination,
      {bool replaceActive = true}) async {
    if (replaceActive && _activeTrip != null) {
      await stopTrip(cancel: true);
    }

    final hasPermission = await _locationEngine.checkPermissions();
    if (!hasPermission) return false;

    // Create trip
    _activeTrip = Trip(
      id: _uuid.v4(),
      destinationName: destination.name,
      destLatitude: destination.latitude,
      destLongitude: destination.longitude,
      destRadius: destination.radius,
    );

    await StorageService.saveTrip(_activeTrip!);
    _tripHistory = StorageService.getTrips();
    _resetAlertMilestones();
    _startTrackingInternal();
    notifyListeners();
    return true;
  }

  void _startTrackingInternal() {
    if (_activeTrip == null) return;

    final destLatLng = LatLng(
      _activeTrip!.destLatitude,
      _activeTrip!.destLongitude,
    );

    _trackingData = TrackingData(
      destination: destLatLng,
      isTracking: true,
    );

    // Setup geofence callbacks
    _geofenceEngine.onZoneChanged = (zone, distance, alertLevel) {
      _locationEngine.updateTrackingZone(zone);
    };

    // Start location tracking
    _locationEngine.startTracking(TrackingZone.far);

    _positionSub = _locationEngine.positionStream.listen((position) {
      _onPositionUpdate(position, destLatLng);
    });

    _speedSub = _locationEngine.speedStream.listen(_onSpeedUpdate);
  }

  void _onPositionUpdate(LatLng position, LatLng destination) {
    final distance = DistanceEngine.calculateDistance(position, destination);
    final zone = DistanceEngine.determineZone(distance);
    final alertLevel = DistanceEngine.determineAlertLevel(distance);

    // Check geofence
    _geofenceEngine.check(position, destination,
        speedKmh: _trackingData.speedKmh);

    // Calculate ETA
    final eta =
        DistanceEngine.calculateETA(distance, _trackingData.speedMps);

    _trackingData = _trackingData.copyWith(
      currentPosition: position,
      distanceMeters: distance,
      zone: zone,
      alertLevel: alertLevel,
      eta: eta,
      isIdle: _locationEngine.isIdle,
      lastUpdate: DateTime.now(),
    );

    // Update foreground notification
    if (_activeTrip != null) {
      _notificationEngine.showTrackingNotification(
          _activeTrip!.destinationName, distance);
      unawaited(_handleDistanceMilestones(distance));
    }

    // Check if arrived
    if (zone == TrackingZone.arrived) {
      _onArrived();
    }

    notifyListeners();
  }

  void _onSpeedUpdate(double speedMps) {
    final speedKmh = speedMps * 3.6;
    final travelMode = _travelDetectionEngine.detectMode(speedKmh);

    _trackingData = _trackingData.copyWith(
      speedMps: speedMps,
      travelMode: travelMode,
    );

    notifyListeners();
  }

  void _onArrived() {
    if (_activeTrip != null && _activeTrip!.status != TripStatus.completed) {
      _activeTrip!.status = TripStatus.completed;
      _activeTrip!.completedAt = DateTime.now();
      StorageService.updateTrip(_activeTrip!);
    }
    // Don't stop tracking immediately — keep alarm going until user dismisses
  }

  Future<void> _handleDistanceMilestones(double distanceMeters) async {
    if (_activeTrip == null) return;

    if (!_triggeredOneKmAlarm && distanceMeters <= 1000) {
      _triggeredOneKmAlarm = true;
      _isAlarmRinging = true;
      await _notificationEngine.triggerMilestoneAlarm(
        title: '1 km remaining',
        body: 'Only ${distanceMeters.toInt()} m to ${_activeTrip!.destinationName}.',
        notificationId: NotificationIds.soundAlert,
      );
      notifyListeners();
    }

    if (!_triggeredThreeHundredAlarm && distanceMeters <= 300) {
      _triggeredThreeHundredAlarm = true;
      _isAlarmRinging = true;
      await _notificationEngine.triggerMilestoneAlarm(
        title: '300 m remaining',
        body: 'Very close to ${_activeTrip!.destinationName}.',
        notificationId: NotificationIds.alarmAlert,
      );
      notifyListeners();
    }

    if (!_triggeredArrivalNotice && distanceMeters <= DistanceThresholds.veryClose) {
      _triggeredArrivalNotice = true;
      _isAlarmRinging = false;
      await _notificationEngine.showArrivalNotification(
        destinationName: _activeTrip!.destinationName,
      );
      notifyListeners();
    }
  }

  Future<void> dismissAlarm() async {
    await _notificationEngine.stopAlarmAudio();
    _isAlarmRinging = false;
    notifyListeners();
  }

  void _resetAlertMilestones() {
    _triggeredOneKmAlarm = false;
    _triggeredThreeHundredAlarm = false;
    _triggeredArrivalNotice = false;
    _isAlarmRinging = false;
  }

  Future<void> stopTrip({bool cancel = false}) async {
    if (_activeTrip != null) {
      _activeTrip!.status =
          cancel ? TripStatus.cancelled : TripStatus.completed;
      _activeTrip!.completedAt = DateTime.now();
      await StorageService.updateTrip(_activeTrip!);
    }

    _locationEngine.stopTracking();
    _positionSub?.cancel();
    _speedSub?.cancel();
    _geofenceEngine.reset();
    _travelDetectionEngine.reset();
    await _notificationEngine.cancelAll();

    _activeTrip = null;
    _trackingData = const TrackingData();
    _tripHistory = StorageService.getTrips();
    _resetAlertMilestones();

    notifyListeners();
  }

  Future<int> clearHistory({bool keepActiveTrip = true}) async {
    final deleted = await StorageService.clearTrips(
      excludeTripId: keepActiveTrip ? _activeTrip?.id : null,
    );
    _tripHistory = StorageService.getTrips();
    notifyListeners();
    return deleted;
  }

  /// Get current location for map display
  Future<LatLng?> getCurrentLocation() async {
    final hasPermission = await _locationEngine.checkPermissions();
    if (!hasPermission) return null;
    return await _locationEngine.getCurrentPosition();
  }

  @override
  void dispose() {
    _locationEngine.dispose();
    _notificationEngine.dispose();
    _positionSub?.cancel();
    _speedSub?.cancel();
    super.dispose();
  }
}
