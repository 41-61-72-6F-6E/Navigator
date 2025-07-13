import 'package:geolocator/geolocator.dart';
import 'package:navigator/models/station.dart';

class Location {
  final String type;
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  String? address;
  
  Location({
    required this.type,
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address
  });
  
  factory Location.fromJson(Map<String, dynamic> json) {

    if(json.containsKey('products') || json.containsKey('ril100Ids'))
    {
      return Station.fromJson(json);
    }
    return Location(
      type: json['type'],
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
    );
  }
  
  factory Location.fromPosition(Position p) {
    return Location(
      type: 'Address', 
      id: '0', 
      name: 'emptyName', 
      latitude: p.latitude, 
      longitude: p.longitude
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}