part of 'invoice.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 18;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };

    return Invoice(
      id: fields[0] as String?,
      orgId: fields[1] as String,
      facilityId: fields[2] as String,
      invoiceNumber: fields[3] as String,
      recordType: fields[4] as int,
      totalAmount: fields[5] as double,
      invoiceDate: fields[6] as DateTime,
      deleted: fields[7] as bool,
      offline: fields[8] as bool,
      isSynced: fields[9] as bool
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orgId)
      ..writeByte(2)
      ..write(obj.facilityId)
      ..writeByte(3)
      ..write(obj.invoiceNumber)
      ..writeByte(4)
      ..write(obj.recordType)
      ..writeByte(5)
      ..write(obj.totalAmount)
      ..writeByte(6)
      ..write(obj.invoiceDate)
      ..writeByte(7)
      ..write(obj.deleted)
      ..writeByte(8)
      ..write(obj.offline)
      ..writeByte(9)
      ..write(obj.isSynced)
    ;
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
