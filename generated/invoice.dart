import 'package:hive/hive.dart';

part 'invoice.g.dart';

@HiveType(typeId: 18)
class Invoice extends HiveObject {

  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String orgId;

  @HiveField(2)
  final String facilityId;

  @HiveField(3)
  final String invoiceNumber;

  @HiveField(4)
  final int recordType;

  @HiveField(5)
  final double totalAmount;

  @HiveField(6)
  final DateTime invoiceDate;

  @HiveField(7)
  final bool deleted;

  @HiveField(8)
  final bool offline;

  @HiveField(9)
  final bool isSynced;


  Invoice({
    this.id,
    required this.orgId,
    required this.facilityId,
    required this.invoiceNumber,
    required this.recordType,
    required this.totalAmount,
    required this.invoiceDate,
    required this.deleted,
    required this.offline,
    required this.isSynced
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString(),
      orgId: json['orgId'].toString(),
      facilityId: json['facilityId'].toString(),
      invoiceNumber: json['invoiceNumber'].toString(),
      recordType: int.tryParse(json['recordType'].toString()) ?? 0,
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      invoiceDate: DateTime.parse(json['invoiceDate'].toString()),
      deleted: json['deleted'] is bool ? json['deleted'] as bool : false,
      offline: json['offline'] is bool ? json['offline'] as bool : true,
      isSynced: json['isSynced'] is bool ? json['isSynced'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'orgId': orgId,
      'facilityId': facilityId,
      'invoiceNumber': invoiceNumber,
      'recordType': recordType,
      'totalAmount': totalAmount,
      'invoiceDate': invoiceDate.toIso8601String(),
      'deleted': deleted,
      'offline': offline,
      'isSynced': isSynced,
    };
  }
}
