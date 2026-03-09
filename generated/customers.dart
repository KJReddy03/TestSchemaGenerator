import 'package:hive/hive.dart';

part 'customers.g.dart';

@HiveType(typeId: 1)
class Customer extends HiveObject {

  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final int age;

  @HiveField(4)
  final Subjects marks;


  Customer({
    this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.marks
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString(),
      name: json['name'].toString(),
      email: json['email'].toString(),
      age: int.tryParse(json['age'].toString()) ?? 0,
      marks: Subjects.fromJson(json['marks'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'age': age,
      'marks': marks.toJson(),
    };
  }
}


@HiveType(typeId: 1)
class Subjects extends HiveObject {

  @HiveField(0)
  final int math;

  @HiveField(1)
  final int physics;

  @HiveField(2)
  final int chemistry;


  Subjects({
    required this.math,
    required this.physics,
    required this.chemistry
  });

  factory Subjects.fromJson(Map<String, dynamic> json) {
    return Subjects(
      math: int.tryParse(json['math'].toString()) ?? 0,
      physics: int.tryParse(json['physics'].toString()) ?? 0,
      chemistry: int.tryParse(json['chemistry'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'math': math,
      'physics': physics,
      'chemistry': chemistry,
    };
  }
}
