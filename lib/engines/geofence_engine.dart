import 'package:latlong2/latlong.dart';
import '../models/tracking_state.dart';
import 'distance_engine.dart';

/// Callback for zone transitions
typedef ZoneCallback = void Function(
    TrackingZone newZone, double distance, AlertLevel alertLevel);

class GeofenceEngine {
  TrackingZone _currentZone = TrackingZone.far;
  AlertLevel _currentAlertLevel = AlertLevel.none;
  ZoneCallback? onZoneChanged;
  ZoneCallback? onAlertLevelChanged;

  TrackingZone get currentZone => _currentZone;
  AlertLevel get currentAlertLevel => _currentAlertLevel;

  /// Check position against geofence and fire callbacks on transitions
  GeofenceResult check(LatLng currentPosition, LatLng destination,
      {double speedKmh = 0}) {
    final distance =
        DistanceEngine.calculateDistance(currentPosition, destination);
    final zone = DistanceEngine.determineZone(distance);
    final alertLevel = DistanceEngine.determineAlertLevel(distance);
    final triggerRadius = DistanceEngine.getTriggerRadius(speedKmh);
    final isWithinGeofence = distance <= triggerRadius;

    // Check for zone transition
    if (zone != _currentZone) {
      _currentZone = zone;
      onZoneChanged?.call(zone, distance, alertLevel);
    }

    // Check for alert level change
    if (alertLevel != _currentAlertLevel) {
      _currentAlertLevel = alertLevel;
      onAlertLevelChanged?.call(zone, distance, alertLevel);
    }

    return GeofenceResult(
      distance: distance,
      zone: zone,
      alertLevel: alertLevel,
      triggerRadius: triggerRadius,
      isWithinGeofence: isWithinGeofence,
    );
  }

  void reset() {
    _currentZone = TrackingZone.far;
    _currentAlertLevel = AlertLevel.none;
  }
}

class GeofenceResult {
  final double distance;
  final TrackingZone zone;
  final AlertLevel alertLevel;
  final double triggerRadius;
  final bool isWithinGeofence;

  const GeofenceResult({
    required this.distance,
    required this.zone,
    required this.alertLevel,
    required this.triggerRadius,
    required this.isWithinGeofence,
  });
}
