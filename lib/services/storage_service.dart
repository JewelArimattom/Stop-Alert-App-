import 'package:hive_flutter/hive_flutter.dart';
import '../models/destination.dart';
import '../models/trip.dart';
import '../utils/constants.dart';

class StorageService {
  static late Box<Destination> _destinationsBox;
  static late Box<Trip> _tripsBox;
  static late Box _settingsBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(DestinationAdapter());
    Hive.registerAdapter(TripAdapter());

    // Open boxes
    _destinationsBox =
        await Hive.openBox<Destination>(HiveBoxes.destinations);
    _tripsBox = await Hive.openBox<Trip>(HiveBoxes.trips);
    _settingsBox = await Hive.openBox(HiveBoxes.settings);
  }

  // ─── Destinations ──────────────────────────────────────────────

  static List<Destination> getDestinations() {
    return _destinationsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveDestination(Destination destination) async {
    await _destinationsBox.put(destination.id, destination);
  }

  static Future<void> deleteDestination(String id) async {
    await _destinationsBox.delete(id);
  }

  static Destination? getDestination(String id) {
    return _destinationsBox.get(id);
  }

  // ─── Trips ─────────────────────────────────────────────────────

  static List<Trip> getTrips() {
    return _tripsBox.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  static Trip? getActiveTrip() {
    try {
      return _tripsBox.values.firstWhere((t) => t.statusIndex == 0);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveTrip(Trip trip) async {
    await _tripsBox.put(trip.id, trip);
  }

  static Future<void> updateTrip(Trip trip) async {
    await trip.save();
  }

  static Future<void> deleteTrip(String id) async {
    await _tripsBox.delete(id);
  }

  static Future<int> clearTrips({String? excludeTripId}) async {
    final keysToDelete = _tripsBox.keys
        .where((key) => key != excludeTripId)
        .toList(growable: false);
    if (keysToDelete.isEmpty) return 0;
    await _tripsBox.deleteAll(keysToDelete);
    return keysToDelete.length;
  }

  // ─── Settings ──────────────────────────────────────────────────

  static T? getSetting<T>(String key) {
    return _settingsBox.get(key) as T?;
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static double getAlertNotifyDistance() {
    return _settingsBox.get('alertNotifyDistance',
        defaultValue: DistanceThresholds.alertNotify) as double;
  }

  static double getAlertSoundDistance() {
    return _settingsBox.get('alertSoundDistance',
        defaultValue: DistanceThresholds.alertSound) as double;
  }

  static double getAlertAlarmDistance() {
    return _settingsBox.get('alertAlarmDistance',
        defaultValue: DistanceThresholds.alertAlarm) as double;
  }

  static bool getVibrationEnabled() {
    return _settingsBox.get('vibrationEnabled', defaultValue: true) as bool;
  }
}
