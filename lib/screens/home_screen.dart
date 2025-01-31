import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/drawer.dart';
import '../widgets/location_button.dart';
import '../widgets/ride_sheet.dart';
import '../widgets/top_navigation.dart';
import 'complaint_screen.dart';
import 'trip_tracking_screen.dart';
import 'wallet_screen.dart';
import '../models/location.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final TextEditingController _destinationController = TextEditingController();

  Location? _currentLocation;
  Location? _destinationLocation;
  List<Location> _searchSuggestions = [];
  List<LatLng> _routePoints = [];
  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  /// الحصول على الموقع الحالي للمستخدم
  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar("يرجى تفعيل خدمة تحديد الموقع");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("تم رفض إذن الموقع");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("إذن الموقع مرفوض بشكل دائم");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentLocation = Location(
          name: "موقعي الحالي",
          coordinates: LatLng(position.latitude, position.longitude),
        );
        // نقل الخريطة إلى الموقع الحالي
        _mapController.move(_currentLocation!.coordinates, 15.0);
      });
    } catch (e) {
      _showSnackBar("فشل في الحصول على الموقع: ${e.toString()}");
    }
  }

  /// البحث عن المواقع بناءً على استعلام المستخدم
  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _routePoints = [];
        _destinationLocation = null;
        _searchSuggestions.clear();
      });
      return;
    }

    final suggestions = await _locationService.searchPlaces(query);
    setState(() {
      _searchSuggestions = suggestions;
    });
  }

  /// عند اختيار الموقع من نتائج البحث
  void _onDestinationSelected(Location location) {
    setState(() {
      _routePoints = [];
      _destinationLocation = location;
      _destinationController.text = location.name;
      _searchSuggestions.clear();
    });
    _getRouteDirections();
  }

  /// الحصول على اتجاهات الطريق بين الموقع الحالي والوجهة
  Future<void> _getRouteDirections() async {
    if (_currentLocation == null || _destinationLocation == null) return;

    setState(() => _isLoading = true);
    try {
      final route = await _locationService.getRouteDirections(
        _currentLocation!.coordinates,
        _destinationLocation!.coordinates,
      );
      setState(() {
        _routePoints = route;
      });
      if (_routePoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_routePoints);
        _mapController.fitBounds(
          bounds,
          options: FitBoundsOptions(padding: const EdgeInsets.all(50)),
        );
      }
    } catch (e) {
      _showSnackBar("فشل في الحصول على الاتجاهات: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(context),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation?.coordinates ?? LatLng(24.7136, 46.6753),
              zoom: 13.0,
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                tileProvider: CachingNetworkTileProvider(),
                additionalOptions: {
                  'accessToken': 'pk.fgf.rBHlP-HWiu071UUoq6E7mA', // استبدل بالمفتاح الصحيح
                  'id': 'mapbox/streets-v11',
                },
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!.coordinates,
                      builder: (ctx) => const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_destinationLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _destinationLocation!.coordinates,
                      builder: (ctx) => const Icon(
                        Icons.flag,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.greenAccent,
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
            ],
          ),
          buildTopNavigation(
            context,
            _destinationController,
            _searchSuggestions,
            _onDestinationSelected,
            _searchLocations,
          ),
          buildLocationButton(_toggleExpanded, _isExpanded),
          buildRideSheet(context),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

/// يقوم هذا الـ TileProvider بتحميل البلاطات باستخدام التخزين المؤقت
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
