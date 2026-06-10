import 'package:navigator/models/baseModel.dart';
import 'package:navigator/models/operator.dart';

class Line extends baseModel{
  final String type;
  final String? id;
  final String? fahrtNr;
  final String name;
  final bool public;
  final String? adminCode;
  final String? productName;
  final String mode;
  final String product;
  final Operator? operator;

  Line({
    required this.type,
    this.id,
    this.fahrtNr,
    required this.name,
    required this.public,
    this.adminCode,
    this.productName,
    required this.mode,
    required this.product,
    this.operator,
    required super.backend,
  });

  factory Line.fromJson(String backend, Map<String, dynamic> json) {
    return Line(
      backend: backend,
      type: json['type'] ?? '',
      id: json['id'],
      fahrtNr: json['fahrtNr'],
      name: json['name'] ?? '',
      public: json['public'] ?? true,
      adminCode: json['adminCode'],
      productName: json['productName'],
      mode: json['mode'] ?? '',
      product: json['product'] ?? '',
      operator: json['operator'] != null ? Operator.fromJson(backend, json['operator']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'fahrtNr': fahrtNr,
      'name': name,
      'public': public,
      'adminCode': adminCode,
      'productName': productName,
      'mode': mode,
      'product': product,
      'operator': operator?.toJson(),
    };
  }
}