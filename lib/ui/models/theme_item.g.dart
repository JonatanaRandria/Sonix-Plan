// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThemeItemAdapter extends TypeAdapter<ThemeItem> {
  @override
  final int typeId = 0;

  @override
  ThemeItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemeItem(
      title: fields[0] as String,
      fbLink: fields[1] as String,
      numberOfParts: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ThemeItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.fbLink)
      ..writeByte(2)
      ..write(obj.numberOfParts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
