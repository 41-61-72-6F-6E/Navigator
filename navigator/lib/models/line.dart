class Line{
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

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
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