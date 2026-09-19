import 'package:navigator/models/baseModel.dart';

class Operator extends baseModel{
  final String type;
  final String id;
  final String name;

  Operator({
    required super.backend,
    required this.type,
    required this.id,
    required this.name,
  });

  factory Operator.fromJson(String backend, Map<String, dynamic> json) {
    return Operator(
      backend: backend,
      type: json['type'] ?? '',
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
    };
  }
}