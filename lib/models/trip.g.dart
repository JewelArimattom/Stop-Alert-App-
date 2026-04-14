// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

class TripAdapter extends TypeAdapter<Trip> {
  @override
  final int typeId = 1;

  @override
  Trip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Trip(
      id: fields[0] as String,
      destinationName: fields[1] as String,
      destLatitude: fields[2] as double,
      destLongitude: fields[3] as double,
      destRadius: fields[4] as double,
      statusIndex: fields[5] as int,
      startedAt: fields[6] as DateTime,
      completedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Trip obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.destinationName)
      ..writeByte(2)
      ..write(obj.destLatitude)
      ..writeByte(3)
      ..write(obj.destLongitude)
      ..writeByte(4)
      ..write(obj.destRadius)
      ..writeByte(5)
      ..write(obj.statusIndex)
      ..writeByte(6)
      ..write(obj.startedAt)
      ..writeByte(7)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
