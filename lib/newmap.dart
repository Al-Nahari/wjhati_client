import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _notesController = TextEditingController();

  LatLng? _currentCoordinates;
  LatLng? _destinationCoordinates;
  List<LatLng> _routePoints = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  /// الحصول على الموقع الحالي للمستخدم والتحقق من صلاحيات الموقع
  Future<void> _fetchCurrentLocation() async {
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

    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentCoordinates = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentCoordinates!, 15.0);
    } catch (e) {
      _showSnackBar("فشل في الحصول على الموقع: ${e.toString()}");
    }
  }

  /// عند النقر على الخريطة يتم تحديد الوجهة ورسم مسار بسيط بين الموقع الحالي والوجهة
  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    if (_currentCoordinates == null) {
      _showSnackBar("لم يتم تحديد موقعك الحالي بعد");
      return;
    }
    setState(() {
      _destinationCoordinates = latlng;
      // رسم خط بسيط من الموقع الحالي إلى الوجهة
      _routePoints = [_currentCoordinates!, _destinationCoordinates!];
    });
  }

  /// إرسال طلب الرحلة عبر HTTP باستخدام JSON
  Future<void> _sendRideRequest() async {
    if (_currentCoordinates == null || _destinationCoordinates == null) {
      _showSnackBar("يجب تحديد الموقع الحالي والوجهة");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // تجهيز البيانات لإرسالها
    Map<String, dynamic> rideData = {
      "from_location": {
        "lat": _currentCoordinates!.latitude,
        "lon": _currentCoordinates!.longitude,
      },
      "to_location": {
        "lat": _destinationCoordinates!.latitude,
        "lon": _destinationCoordinates!.longitude,
      },
      "departure_time": DateTime.now().toIso8601String(),
      "notes": _notesController.text,
    };
print(rideData);
    // استبدل عنوان URL أدناه بعنوان API الخاص بك
    String url = "http://192.168.0.159:8000/cashe-bookings/";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(rideData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("تم إرسال الطلب بنجاح");
      } else {
        _showSnackBar("حدث خطأ أثناء إرسال الطلب: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء إرسال الطلب: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// دالة لعرض رسالة قصيرة (SnackBar)
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // مركز افتراضي في حال عدم توفر الموقع الحالي
    LatLng defaultCenter = LatLng(24.7136, 46.6753);

    return Scaffold(
      appBar: AppBar(
        title: const Text("طلب رحلة"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentCoordinates ?? defaultCenter,
              zoom: 13.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.myapp',
              ),
              if (_currentCoordinates != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentCoordinates!,
                      builder: (ctx) => const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_destinationCoordinates != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _destinationCoordinates!,
                      builder: (ctx) => const Icon(
                        Icons.location_on,
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
                      color: Colors.green,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
            ],
          ),
          // واجهة الإدخال في أسفل الشاشة (حقل الملاحظات وزر "تأكيد الطلب")
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: "ملاحظات",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _sendRideRequest,
                      child: const Text("تأكيد الطلب"),
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
}
