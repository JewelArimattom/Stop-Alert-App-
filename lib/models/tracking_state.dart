import 'package:latlong2/latlong.dart';

/// Tracking zone based on distance to destination
enum TrackingZone { far, mid, near, veryClose, arrived }

/// Travel mode detected by speed
enum TravelMode { stationary, walking, bus, train }

/// Alert level based on proximity
enum AlertLevel { none, notification, sound, alarm }

/// Full tracking state
class TrackingData {
  final LatLng? currentPosition;
  final LatLng? destination;
  final double distanceMeters;
  final double speedMps; // meters per second
  final TrackingZone zone;
  final TravelMode travelMode;
  final AlertLevel alertLevel;
  final Duration? eta;
  final bool isTracking;
  final bool isIdle;
  final DateTime? lastUpdate;

  const TrackingData({
    this.currentPosition,
    this.destination,
    this.distanceMeters = 0,
    this.speedMps = 0,
    this.zone = TrackingZone.far,
    this.travelMode = TravelMode.stationary,
    this.alertLevel = AlertLevel.none,
    this.eta,
    this.isTracking = false,
    this.isIdle = false,
    this.lastUpdate,
  });

  double get speedKmh => speedMps * 3.6;

  TrackingData copyWith({
    LatLng? currentPosition,
    LatLng? destination,
    double? distanceMeters,
    double? speedMps,
    TrackingZone? zone,
    TravelMode? travelMode,
    AlertLevel? alertLevel,
    Duration? eta,
    bool? isTracking,
    bool? isIdle,
    DateTime? lastUpdate,
  }) {
    return TrackingData(
      currentPosition: currentPosition ?? this.currentPosition,
      destination: destination ?? this.destination,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      speedMps: speedMps ?? this.speedMps,
      zone: zone ?? this.zone,
      travelMode: travelMode ?? this.travelMode,
      alertLevel: alertLevel ?? this.alertLevel,
      eta: eta ?? this.eta,
      isTracking: isTracking ?? this.isTracking,
      isIdle: isIdle ?? this.isIdle,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
