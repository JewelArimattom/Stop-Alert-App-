import '../models/tracking_state.dart';
import '../utils/constants.dart';

class TravelDetectionEngine {
  final List<double> _speedHistory = [];
  static const int maxHistory = 10;

  /// Detect travel mode based on current speed (km/h)
  TravelMode detectMode(double speedKmh) {
    _speedHistory.add(speedKmh);
    if (_speedHistory.length > maxHistory) {
      _speedHistory.removeAt(0);
    }

    // Use average of recent speeds for smoother detection
    final avgSpeed =
        _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;

    if (avgSpeed < SpeedThresholds.walking) return TravelMode.stationary;
    if (avgSpeed < SpeedThresholds.bus) return TravelMode.walking;
    if (avgSpeed < SpeedThresholds.train) return TravelMode.bus;
    return TravelMode.train;
  }

  /// Get travel mode display info
  static TravelModeInfo getModeInfo(TravelMode mode) {
    switch (mode) {
      case TravelMode.stationary:
        return const TravelModeInfo(
          name: 'Stationary',
          emoji: '⏸️',
          description: 'Not moving',
        );
      case TravelMode.walking:
        return const TravelModeInfo(
          name: 'Walking',
          emoji: '🚶',
          description: 'On foot',
        );
      case TravelMode.bus:
        return const TravelModeInfo(
          name: 'Bus',
          emoji: '🚌',
          description: 'Bus speed detected',
        );
      case TravelMode.train:
        return const TravelModeInfo(
          name: 'Train',
          emoji: '🚆',
          description: 'High speed detected',
        );
    }
  }

  void reset() {
    _speedHistory.clear();
  }
}

class TravelModeInfo {
  final String name;
  final String emoji;
  final String description;

  const TravelModeInfo({
    required this.name,
    required this.emoji,
    required this.description,
  });
}
