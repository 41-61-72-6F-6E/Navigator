import 'package:navigator/models/baseModel.dart';

class Line extends baseModel{
  final String? type;
  final String? id;
  final String? fahrtNr;
  final String? name;
  final bool? public;
  final String? productName;
  final String? mode;
  final String? product;
  final String? operator;
  Line({
    required super.backend,
    this.type,
    this.id,
    this.fahrtNr,
    this.name,
    this.public,
    this.productName,
    this.mode,
    this.product,
    this.operator,
  });

  factory Line.fromJson(String backend, Map<String, dynamic> json) {
    return Line(
      backend: backend,
      type: json['type'],
      id: json['id'],
      fahrtNr: json['fahrtNr'],
      name: json['name'],
      public: json['public'],
      productName: json['productName'],
      mode: json['mode'],
      product: json['product'],
      operator: json['operator'],
    );
  }
}