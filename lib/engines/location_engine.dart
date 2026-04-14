import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/tracking_state.dart';
import '../utils/constants.dart';

class LocationEngine {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _pollingTimer;
  final _positionController = StreamController<LatLng>.broadcast();
  final _speedController = StreamController<double>.broadcast();

  LatLng? _lastPosition;
  DateTime? _lastMovementTime;
  bool _isIdle = false;

  Stream<LatLng> get positionStream => _positionController.stream;
  Stream<double> get speedStream => _speedController.stream;
  bool get isIdle => _isIdle;

  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Get current position once
  Future<LatLng?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      _lastPosition = latLng;
      return latLng;
    } catch (e) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) return null;
        final latLng =
            LatLng(lastKnown.latitude, lastKnown.longitude);
        _lastPosition = latLng;
        return latLng;
      } catch (_) {
        return null;
      }
    }
  }

  /// Start adaptive tracking based on current zone
  void startTracking(TrackingZone zone) {
    stopTracking();

    final interval = _getIntervalForZone(zone);
    final accuracy = _getAccuracyForZone(zone);

    _pollingTimer = Timer.periodic(Duration(seconds: interval), (_) async {
      await _fetchPosition(accuracy);
    });

    // Also do an immediate fetch
    _fetchPosition(accuracy);
  }

  /// Update tracking interval when zone changes
  void updateTrackingZone(TrackingZone zone) {
    startTracking(zone);
  }

  Future<void> _fetchPosition(LocationAccuracy accuracy) async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) return;

      final latLng = LatLng(position.latitude, position.longitude);
      final speed = position.speed.clamp(0.0, 200.0); // m/s, clamped

      // Check for idle
      if (_lastPosition != null) {
        final dist =
            const Distance().as(LengthUnit.Meter, _lastPosition!, latLng);
        if (dist < BatteryConfig.minMovementMeters) {
          _lastMovementTime ??= DateTime.now();
          final idleDuration =
              DateTime.now().difference(_lastMovementTime!).inMinutes;
          _isIdle = idleDuration >= BatteryConfig.idleTimeoutMinutes;
        } else {
          _lastMovementTime = DateTime.now();
          _isIdle = false;
        }
      }

      _lastPosition = latLng;
      _positionController.add(latLng);
      _speedController.add(speed);
    } catch (e) {
      // GPS error - skip this update
    }
  }

  int _getIntervalForZone(TrackingZone zone) {
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

  LocationAccuracy _getAccuracyForZone(TrackingZone zone) {
    switch (zone) {
      case TrackingZone.far:
        return LocationAccuracy.low;
      case TrackingZone.mid:
        return LocationAccuracy.medium;
      case TrackingZone.near:
        return LocationAccuracy.high;
      case TrackingZone.veryClose:
      case TrackingZone.arrived:
        return LocationAccuracy.best;
    }
  }

  void stopTracking() {
    _pollingTimer?.cancel();
    _positionSubscription?.cancel();
    _pollingTimer = null;
    _positionSubscription = null;
    _isIdle = false;
    _lastMovementTime = null;
  }

  void dispose() {
    stopTracking();
    _positionController.close();
    _speedController.close();
  }
}
