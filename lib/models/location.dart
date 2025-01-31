import 'package:latlong2/latlong.dart';

class Location {
  final String name;
  final LatLng coordinates;

  Location({
    required this.name,
    required this.coordinates,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'coordinates': {
      'lat': coordinates.latitude,
      'lng': coordinates.longitude
    }
  };
}