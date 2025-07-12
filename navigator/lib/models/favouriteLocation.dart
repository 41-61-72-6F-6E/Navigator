import 'dart:convert';
import 'package:navigator/models/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteLocation {
  final String name;
  final Location location;

  FavoriteLocation({required this.name, required this.location});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location.toJson(),
    };
  }

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    return FavoriteLocation(
      name: json['name'] as String,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
    );
  }
}