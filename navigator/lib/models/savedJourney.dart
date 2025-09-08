import 'package:navigator/models/journey.dart';

class Savedjourney 
{
  Journey journey;
  String id;

  Savedjourney({required this.journey, required this.id});

  Map<String, dynamic> toJson() {
    return {
      'journey': journey.toJson(),
      'id': id,
    };
  }

  factory Savedjourney.fromJson(Map<String, dynamic> json) {
    return Savedjourney(
      id: json['id'] as String,
      journey: Journey.fromJson(json['journey'] as Map<String, dynamic>),
    );
  }
}