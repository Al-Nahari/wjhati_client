import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/location.dart';

class LocationService {
  final String mapboxAccessToken = 'pk.eyJ1IjoidmlydHVzc29mdCIsImEiOiJjbTZrbnp6YTMwMDc4MmpzODBpbTEyeHJtIn0.rBHlP-HWiu071UUoq6E7mA';

  Future<List<LatLng>> getRouteDirections(LatLng start, LatLng end) async {
    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&access_token=$mapboxAccessToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'][0];
        final geometry = routes['geometry']['coordinates'] as List;
        return geometry.map((coord) => LatLng(coord[1], coord[0])).toList();
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      throw Exception('Error getting route: $e');
    }
  }
  Future<List<Location>> searchPlaces(String query) async {
    // حدود تقريبية تغطي صنعاء وذمار
    final String bbox = '43.5,13.7,44.8,15.8'; // (minLon,minLat,maxLon,maxLat)

    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json"
        "?access_token=$mapboxAccessToken"
        "&language=ar"
        "&bbox=$bbox"
        "&limit=10"; // اختيار عدد محدود من النتائج

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List features = data['features'];

      // فلترة إضافية للتأكد أن النتائج ضمن صنعاء أو ذمار
      final filtered = features.where((place) {
        final placeName = place['place_name_ar'] ?? place['place_name'] ?? '';
        return placeName.contains('صنعاء') || placeName.contains('ذمار');
      }).toList();

      return filtered.map((place) {
        return Location(
          name: place['place_name_ar'] ?? place['place_name'],
          coordinates: LatLng(
            place['center'][1],
            place['center'][0],
          ),
        );
      }).toList();
    } else {
      return [];
    }
  }
}