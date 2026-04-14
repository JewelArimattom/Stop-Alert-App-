import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/tracking_state.dart';
import '../utils/constants.dart';

class DistanceEngine {
  /// Calculate distance between two points using Haversine formula (meters)
  static double calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000; // meters

    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude)) *
            cos(_toRadians(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Calculate ETA based on current speed
  static Duration? calculateETA(double distanceMeters, double speedMps) {
    if (speedMps <= 0.5) return null; // Too slow to estimate
    final seconds = distanceMeters / speedMps;
    if (seconds > 86400) return null; // More than 24 hours
    return Duration(seconds: seconds.toInt());
  }

  /// Determine tracking zone based on distance
  static TrackingZone determineZone(double distanceMeters) {
    if (distanceMeters > DistanceThresholds.far) return TrackingZone.far;
    if (distanceMeters > DistanceThresholds.mid) return TrackingZone.mid;
    if (distanceMeters > DistanceThresholds.near) return TrackingZone.near;
    if (distanceMeters > DistanceThresholds.veryClose) {
      return TrackingZone.veryClose;
    }
    return TrackingZone.arrived;
  }

  /// Determine alert level based on distance
  static AlertLevel determineAlertLevel(double distanceMeters) {
    if (distanceMeters <= DistanceThresholds.veryClose) {
      return AlertLevel.alarm;
    }
    if (distanceMeters <= DistanceThresholds.near) return AlertLevel.sound;
    if (distanceMeters <= DistanceThresholds.far) {
      return AlertLevel.notification;
    }
    return AlertLevel.none;
  }

  /// Get dynamic trigger radius based on speed
  static double getTriggerRadius(double speedKmh) {
    if (speedKmh > SpeedThresholds.train) return TriggerRadius.train;
    if (speedKmh > SpeedThresholds.bus) return TriggerRadius.bus;
    return TriggerRadius.walking;
  }

  static double _toRadians(double degrees) => degrees * (pi / 180);
}
