// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publications.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PublicationAdapter extends TypeAdapter<Publication> {
  @override
  final int typeId = 1;

  @override
  Publication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Publication(
      title: fields[0] as String,
      fbLink: fields[1] as String,
      datePublished: fields[2] as DateTime?,
      slotTime: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Publication obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.fbLink)
      ..writeByte(2)
      ..write(obj.datePublished)
      ..writeByte(3)
      ..write(obj.slotTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
