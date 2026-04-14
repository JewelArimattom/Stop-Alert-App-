import 'package:hive/hive.dart';

part 'destination.g.dart';

@HiveType(typeId: 0)
class Destination extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final double radius; // meters

  @HiveField(5)
  final DateTime createdAt;

  Destination({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 500,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        radius: json['radius'] as double,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
