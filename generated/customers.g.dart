part of 'customers.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 1;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };

    return Customer(
      id: fields[0] as String?,
      name: fields[1] as String,
      email: fields[2] as String,
      age: fields[3] as int,
      marks: fields[4] as Subjects
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.marks)
    ;
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}


// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubjectsAdapter extends TypeAdapter<Subjects> {
  @override
  final int typeId = 1;

  @override
  Subjects read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };

    return Subjects(
      math: fields[0] as int,
      physics: fields[1] as int,
      chemistry: fields[2] as int
    );
  }

  @override
  void write(BinaryWriter writer, Subjects obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.math)
      ..writeByte(1)
      ..write(obj.physics)
      ..writeByte(2)
      ..write(obj.chemistry)
    ;
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
