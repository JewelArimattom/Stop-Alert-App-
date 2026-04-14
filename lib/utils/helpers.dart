import 'dart:math';

class Helpers {
  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  /// Format speed for display
  static String formatSpeed(double metersPerSecond) {
    final kmh = metersPerSecond * 3.6;
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  /// Format ETA duration
  static String formatETA(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
    return '${duration.inSeconds}s';
  }

  /// Convert degrees to radians
  static double toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get travel mode icon
  static String getTravelModeEmoji(String mode) {
    switch (mode) {
      case 'train':
        return '🚆';
      case 'bus':
        return '🚌';
      case 'walking':
        return '🚶';
      default:
        return '📍';
    }
  }

  /// Get zone color name
  static String getZoneName(String zone) {
    switch (zone) {
      case 'FAR':
        return 'Far Away';
      case 'MID':
        return 'Getting Closer';
      case 'NEAR':
        return 'Almost There';
      case 'VERY_CLOSE':
      case 'VERYCLOSE':
        return 'Very Close!';
      case 'ARRIVED':
        return 'Arrived!';
      default:
        return 'Unknown';
    }
  }
}
