import 'package:navigator/models/location.dart';

class Station extends Location {
  final bool nationalExpress;
  final bool national;
  final bool regional;
  final bool regionalExpress;
  final bool suburban;
  final bool bus;
  final bool ferry;
  final bool subway;
  final bool tram;
  final bool taxi;
  final List<String> ril100Ids; // Added RIL100 IDs

  Station({
    required super.type,
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required this.nationalExpress,
    required this.national,
    required this.regional,
    required this.regionalExpress,
    required this.suburban,
    required this.bus,
    required this.ferry,
    required this.subway,
    required this.tram,
    required this.taxi,
    required this.ril100Ids, // Added to constructor
  });

  factory Station.empty() {
    return Station(
      type: '',
      id: '',
      name: '',
      latitude: 0,
      longitude: 0,
      nationalExpress: false,
      national: false,
      regional: false,
      regionalExpress: false,
      suburban: false,
      bus: false,
      ferry: false,
      subway: false,
      tram: false,
      taxi: false,
      ril100Ids: [], // Empty list for empty station
    );
  }

  @override
  factory Station.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final products = json['products'];
    
    // Parse RIL100 IDs - handle both direct array and nested station structure
    List<String> parseRil100Ids(Map<String, dynamic> data) {
      if (data['ril100Ids'] != null) {
        return List<String>.from(data['ril100Ids']);
      }
      // Check if there's a nested station with ril100Ids
      if (data['station']?['ril100Ids'] != null) {
        return List<String>.from(data['station']['ril100Ids']);
      }
      return [];
    }

    return Station(
      type: json['type'] ?? '',
      id: json['id'] ?? location?['id'] ?? '',
      name: json['name'] ?? '',
      latitude: location?['latitude'] ?? json['latitude'] ?? 0.0,
      longitude: location?['longitude'] ?? json['longitude'] ?? 0.0,
      nationalExpress: products?['nationalExpress'] ?? false,
      national: products?['national'] ?? false,
      regional: products?['regional'] ?? false,
      regionalExpress: products?['regionalExpress'] ?? false,
      suburban: products?['suburban'] ?? false,
      bus: products?['bus'] ?? false,
      ferry: products?['ferry'] ?? false,
      subway: products?['subway'] ?? false,
      tram: products?['tram'] ?? false,
      taxi: products?['taxi'] ?? false,
      ril100Ids: parseRil100Ids(json), // Parse RIL100 IDs
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'products': {
        'nationalExpress': nationalExpress,
        'national': national,
        'regional': regional,
        'regionalExpress': regionalExpress,
        'suburban': suburban,
        'bus': bus,
        'ferry': ferry,
        'subway': subway,
        'tram': tram,
        'taxi': taxi,
      },
      'ril100Ids': ril100Ids, // Include RIL100 IDs in JSON output
    };
  }
}