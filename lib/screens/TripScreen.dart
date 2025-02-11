import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../services/AuthService.dart';
import '../services/location_service.dart';

/// كلاس بيانات المسار المُسترجَع من Mapbox
class RouteInfo {
  final List<LatLng> points;
  final double distance; // بالمتر
  final double duration; // بالثواني

  RouteInfo({
    required this.points,
    required this.distance,
    required this.duration,
  });
}

/// خدمة تحديد المسار باستخدام Mapbox (تعتمد على من and to فقط)
class LocationService {
  // استبدل بالتوكن الخاص بك أو استخدم التوكن الحالي
  final String mapboxAccessToken =
      'pk.eyJ1IjoidmlydHVzc29mdCIsImEiOiJjbTZrbnp6YTMwMDc4MmpzODBpbTEyeHJtIn0.rBHlP-HWiu071UUoq6E7mA';

  Future<RouteInfo> getRouteDirections(LatLng start, LatLng end) async {
    // استخدام معلمة overview=full للحصول على مسار مفصل
    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full&access_token=$mapboxAccessToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final route = data['routes'][0];
        final geometry = route['geometry']['coordinates'] as List;
        final List<LatLng> points = geometry
            .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
            .toList();
        final double distance = route['distance'];
        final double duration = route['duration'];
        return RouteInfo(points: points, distance: distance, duration: duration);
      } else {
        throw Exception('فشل تحميل المسار');
      }
    } catch (e) {
      throw Exception('خطأ أثناء جلب المسار: $e');
    }
  }
}

/// صفحة تفاصيل الرحلة التي تعتمد على from_location و to_location فقط لتحديد المسار
class TripDetailsPage extends StatefulWidget {
  final int tripId;
  const TripDetailsPage({Key? key, required this.tripId}) : super(key: key);

  @override
  _TripDetailsPageState createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  bool isLoading = true;
  Map<String, dynamic>? tripData;
  String errorMessage = '';

  LatLng? fromLatLng;
  LatLng? toLatLng;
  List<LatLng> routePoints = [];
  double? routeDistance;
  double? routeDuration;

  @override
  void initState() {
    super.initState();
    _fetchTripDetails();
  }

  /// جلب تفاصيل الرحلة من الخادم واعتماد تحديد المسار باستخدام from_location و to_location فقط
  Future<void> _fetchTripDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();
      final url = Uri.parse('http://192.168.1.9:8000/trips/${widget.tripId}/');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          tripData = data;
          fromLatLng = _parseCoordinate(data['from_location']);
          toLatLng = _parseCoordinate(data['to_location']);
        });
        if (fromLatLng != null && toLatLng != null) {
          try {
            final routeInfo = await LocationService().getRouteDirections(fromLatLng!, toLatLng!);
            setState(() {
              routePoints = routeInfo.points;
              routeDistance = routeInfo.distance;
              routeDuration = routeInfo.duration;
              isLoading = false;
            });
          } catch (e) {
            setState(() {
              errorMessage = 'فشل جلب المسار: $e';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'بيانات المواقع غير صحيحة.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'حدث خطأ: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء الاتصال بالخادم: $e';
        isLoading = false;
      });
    }
  }

  /// تحويل سلسلة الإحداثيات مثل "14.538331, 44.3883063" إلى كائن LatLng
  LatLng? _parseCoordinate(String coordinate) {
    try {
      final parts = coordinate.split(',');
      if (parts.length < 2) return null;
      final lat = double.parse(parts[0].trim());
      final lon = double.parse(parts[1].trim());
      return LatLng(lat, lon);
    } catch (e) {
      return null;
    }
  }

  /// بناء الخريطة مع تكبيرها (ارتفاع 400 بكسل) وعرض المسار التفصيلي والعلامات
  Widget _buildMap() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            center: fromLatLng ?? LatLng(0, 0),
            zoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
              tileProvider: CachingNetworkTileProvider(),
              additionalOptions: {
                'accessToken':
                'pk.eyJ1IjoidmlydHVzc29mdCIsImEiOiJjbTZrbnp6YTMwMDc4MmpzODBpbTEyeHJtIn0.rBHlP-HWiu071UUoq6E7mA',
                'id': 'mapbox/streets-v11',
              },
            ),
            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Colors.blueAccent,
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (fromLatLng != null)
                  Marker(
                    point: fromLatLng!,
                    width: 50,
                    height: 50,
                    builder: (context) => const Icon(
                      Icons.my_location,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                if (toLatLng != null)
                  Marker(
                    point: toLatLng!,
                    width: 50,
                    height: 50,
                    builder: (context) => const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء تفاصيل الرحلة مع عرض الخريطة والمعلومات الخاصة بالمسافة والمدة
  Widget _buildTripDetails() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMap(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم الرحلة: ${tripData!['id']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('من: ${tripData!['from_location']}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('إلى: ${tripData!['to_location']}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (routeDistance != null && routeDuration != null)
                      Row(
                        children: [
                          const Icon(Icons.directions),
                          const SizedBox(width: 8),
                          Text('المسافة: ${(routeDistance! / 1000).toStringAsFixed(2)} كم'),
                          const SizedBox(width: 16),
                          Text('المدة: ${(routeDuration! / 60).toStringAsFixed(0)} دقيقة'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الرحلة'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: const TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      )
          : _buildTripDetails(),
    );
  }
}

/// كلاس لتحميل بلاطات الخريطة مع التخزين المؤقت باستخدام مكتبة CachedNetworkImage
class CachingNetworkTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (options.urlTemplate == null ||
        options.additionalOptions['id'] == null ||
        options.additionalOptions['accessToken'] == null) {
      throw Exception("Missing required tile layer options.");
    }

    final url = options.urlTemplate!
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{id}', options.additionalOptions['id']!)
        .replaceAll('{accessToken}', options.additionalOptions['accessToken']!);
    return CachedNetworkImageProvider(url);
  }
}
