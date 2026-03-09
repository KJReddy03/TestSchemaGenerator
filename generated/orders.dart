import 'package:hive/hive.dart';

part 'orders.g.dart';

@HiveType(typeId: 3)
class Order extends HiveObject {

  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final int age;


  Order({
    this.id,
    required this.name,
    required this.email,
    required this.age
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString(),
      name: json['name'].toString(),
      email: json['email'].toString(),
      age: int.tryParse(json['age'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'age': age,
    };
  }
}
