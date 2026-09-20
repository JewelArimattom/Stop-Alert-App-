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

// ─── UI Constants — Premium Green & Pearl White Theme ───────────
class AppColors {
  // Primary palette — pearl white & soft sage
  static const Color background = Color(0xFFF5F7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEFF2EA);
  static const Color card = Color(0xFFFFFFFF);

  // Glass effect
  static const Color glass = Color(0x18388E3C);
  static const Color glassBorder = Color(0x20388E3C);

  // Borders, dividers & shadows
  static const Color border = Color(0xFFE2E8D8);
  static const Color borderLight = Color(0xFFD6DFC8);
  static const Color cardShadow = Color(0x141B3B1B);

  // Accent colors — premium green
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF1B5E20);

  // Status colors
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);

  // Text — dark on light
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5C6B5C);
  static const Color textMuted = Color(0xFF9CA89C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF9A825), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF5F7F2), Color(0xFFEFF2EA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F7F2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x10388E3C), Color(0x05388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
