import 'package:hive/hive.dart';
import 'destination.dart';

part 'trip.g.dart';

@HiveType(typeId: 1)
class Trip extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String destinationName;

  @HiveField(2)
  final double destLatitude;

  @HiveField(3)
  final double destLongitude;

  @HiveField(4)
  final double destRadius;

  @HiveField(5)
  int statusIndex; // 0=active, 1=completed, 2=cancelled

  @HiveField(6)
  final DateTime startedAt;

  @HiveField(7)
  DateTime? completedAt;

  Trip({
    required this.id,
    required this.destinationName,
    required this.destLatitude,
    required this.destLongitude,
    this.destRadius = 500,
    this.statusIndex = 0,
    DateTime? startedAt,
    this.completedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  TripStatus get status => TripStatus.values[statusIndex];
  set status(TripStatus s) => statusIndex = s.index;

  Destination get destination => Destination(
        id: id,
        name: destinationName,
        latitude: destLatitude,
        longitude: destLongitude,
        radius: destRadius,
      );

  String get durationString {
    final end = completedAt ?? DateTime.now();
    final diff = end.difference(startedAt);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }
}

enum TripStatus { active, completed, cancelled }
