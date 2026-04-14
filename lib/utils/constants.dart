import 'package:flutter/material.dart';

// ─── Distance Thresholds (meters) ────────────────────────────────
class DistanceThresholds {
  static const double far = 10000; // > 10km
  static const double mid = 2000; // 2–10km
  static const double near = 500; // 500m–2km
  static const double veryClose = 200; // < 500m

  // Alert distances
  static const double alertNotify = 1000;
  static const double alertSound = 500;
  static const double alertAlarm = 200;
}

// ─── Tracking Intervals (seconds) ───────────────────────────────
class TrackingIntervals {
  static const int far = 30;
  static const int mid = 10;
  static const int near = 5;
  static const int veryClose = 2;
}

// ─── Speed Thresholds (km/h) ────────────────────────────────────
class SpeedThresholds {
  static const double train = 60;
  static const double bus = 30;
  static const double walking = 5;
}

// ─── Trigger Radius Based on Speed (meters) ─────────────────────
class TriggerRadius {
  static const double train = 1000;
  static const double bus = 500;
  static const double walking = 200;
}

// ─── Battery Optimization ───────────────────────────────────────
class BatteryConfig {
  static const int idleTimeoutMinutes = 5;
  static const double minMovementMeters = 10;
}

// ─── UI Constants ───────────────────────────────────────────────
class AppColors {
  // Primary palette
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF1A1F36);
  static const Color surfaceLight = Color(0xFF252A42);
  static const Color card = Color(0xFF1E2340);

  // Accent colors
  static const Color primary = Color(0xFF00D68F);
  static const Color primaryLight = Color(0xFF33E0A5);
  static const Color primaryDark = Color(0xFF00A86B);

  // Status colors
  static const Color warning = Color(0xFFFFB800);
  static const Color danger = Color(0xFFFF3D71);
  static const Color info = Color(0xFF0095FF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D1);
  static const Color textMuted = Color(0xFF6B7394);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D68F), Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF3D71), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E21), Color(0xFF141832)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─── Hive Box Names ─────────────────────────────────────────────
class HiveBoxes {
  static const String destinations = 'destinations';
  static const String trips = 'trips';
  static const String settings = 'settings';
}

// ─── Notification IDs ───────────────────────────────────────────
class NotificationIds {
  static const int trackingService = 1;
  static const int proximityAlert = 2;
  static const int soundAlert = 3;
  static const int alarmAlert = 4;
}
