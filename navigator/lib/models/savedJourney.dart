import 'package:navigator/models/journey.dart';

class Savedjourney 
{
  Journey journey;
  int id;

  Savedjourney({required this.journey, required this.id});

  Map<String, dynamic> toJson() {
    return {
      'journey': journey.toJson(),
      'id': id,
    };
  }

  factory Savedjourney.fromJson(Map<String, dynamic> json) {
    return Savedjourney(
      id: json['id'] as int,
      journey: Journey.fromJson(json['location'] as Map<String, dynamic>),
    );
  }
}