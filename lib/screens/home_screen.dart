import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../widgets/drawer.dart';
import '../widgets/location_button.dart';
import '../widgets/top_navigation.dart';
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

  // Controllers للنموذج الافتراضي
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _passengersController = TextEditingController(text: "1");
  final TextEditingController _notesController = TextEditingController();

  // Controller للنموذج البديل
  final TextEditingController _weightController = TextEditingController();

  Location? _currentLocation;
  Location? _destinationLocation;
  List<Location> _searchSuggestions = [];
  List<LatLng> _routePoints = [];
  bool _isExpanded = false;
  bool _isLoading = false;

  // متغير لتحديد نوع الحجز:
  // false: النموذج الافتراضي
  // true: النموذج البديل
  bool _isAlternateBooking = false;
  bool _urgent = false;

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

  /// تفعيل النموذج البديل عند الضغط على أيقونة "UberX"
  void _selectAlternateBooking() {
    setState(() {
      _isAlternateBooking = true;
      _notesController.text = "pending";
      _weightController.text = "7.00";
      _urgent = false;
    });
  }

  /// إعادة الحالة إلى النموذج الافتراضي عند الضغط على أيقونات "Uber Black" أو "Uber XL"
  void _selectDefaultBooking() {
    setState(() {
      _isAlternateBooking = false;
      _weightController.clear();
      // يمكن إعادة تعيين قيم أخرى إن لزم الأمر
    });
  }

  /// دالة لإرسال بيانات الحجز إلى السيرفر باستخدام نقطة النهاية المناسبة
  Future<void> _sendBooking() async {
    if (_currentLocation == null || _destinationLocation == null) {
      _showSnackBar("الموقع الحالي أو الوجهة غير محددة");
      return;
    }

    Map<String, dynamic> bookingData;
    String endpoint;

    if (_isAlternateBooking) {
      // إعداد البيانات للنموذج البديل
      final now = DateTime.now().toUtc().toIso8601String();
      bookingData = {
        "id": 1,
        "created_at": now,
        "updated_at": now,
        "from_location":
        "${_currentLocation!.coordinates.latitude}, ${_currentLocation!.coordinates.longitude}",
        "to_location":
        "${_destinationLocation!.coordinates.latitude}, ${_destinationLocation!.coordinates.longitude}",
        "item_description": _notesController.text.trim(),
        "weight": _weightController.text.trim(),
        "urgent": _urgent,
        "status": "pending",
        "user": 1
      };
      // نقطة النهاية الخاصة بالنموذج البديل
      endpoint = 'http://192.168.1.9:8000/cashe-item-deliveries/';
    } else {
      // إعداد البيانات للنموذج الافتراضي
      String departureTime = _departureTimeController.text.trim();
      int passengers = int.tryParse(_passengersController.text.trim()) ?? 1;
      String notes = _notesController.text.trim();

      if (departureTime.isEmpty) {
        departureTime = "2025-02-04T00:50:16Z";
      }

      bookingData = {
        "from_location":
        "${_currentLocation!.coordinates.latitude}, ${_currentLocation!.coordinates.longitude}",
        "to_location":
        "${_destinationLocation!.coordinates.latitude}, ${_destinationLocation!.coordinates.longitude}",
        "departure_time": departureTime,
        "passengers": passengers,
        "notes": notes,
        "user": 1
      };
      // نقطة النهاية الخاصة بالنموذج الافتراضي
      endpoint = 'http://192.168.1.9:8000/cashe-bookings/';
    }

    final url = Uri.parse(endpoint);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(bookingData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("تم إرسال الحجز بنجاح");
      } else {
        _showSnackBar("فشل إرسال الحجز: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء إرسال الحجز: $e");
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
      drawer: AppDrawer( userData: {},),
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
                  'accessToken':
                  'pk.eyJ1IjoidmlydHVzc29mdCIsImEiOiJjbTZrbnp6YTMwMDc4MmpzODBpbTEyeHJtIn0.rBHlP-HWiu071UUoq6E7mA',
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
          buildLocationButton(_toggleExpanded, _isExpanded, context),
          buildRideSheet(
            context,
            onConfirm: _sendBooking,
            departureController: _departureTimeController,
            passengersController: _passengersController,
            notesController: _notesController,
            isAlternateBooking: _isAlternateBooking,
            weightController: _weightController,
            urgent: _urgent,
            onUrgentChanged: (value) {
              setState(() {
                _urgent = value;
              });
            },
            onSelectAlternate: _selectAlternateBooking,
            onSelectDefault: _selectDefaultBooking,
          ),
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

/// حقل إدخال نصي مع إمكانية تمرير Controller (إن وجد)
Widget _buildInputField(String hintText, IconData icon, TextInputType keyboardType, {TextEditingController? controller}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    ),
    keyboardType: keyboardType,
  );
}

/// حقل تاريخ يتم اختياره من خلال DatePicker ويتم تحديث نصه بواسطة Controller
Widget _buildDateField(BuildContext context, String hintText, IconData icon, {required TextEditingController controller}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    ),
    readOnly: true,
    onTap: () async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        controller.text = pickedDate.toUtc().toIso8601String();
      }
    },
  );
}

/// خيار أيقونة بسيط مع تسمية
Widget _buildIconOption(IconData icon, String label, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 40, color: color),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color
          ),
        ),
      ],
    ),
  );
}

/// ورقة الطلب (Ride Sheet) التي تعرض حقول الإدخال وخيارات الحجز
Widget buildRideSheet(
    BuildContext context, {
      required VoidCallback onConfirm,
      required TextEditingController departureController,
      required TextEditingController passengersController,
      required TextEditingController notesController,
      // باراميترات النموذج البديل:
      bool isAlternateBooking = false,
      TextEditingController? weightController,
      bool urgent = false,
      ValueChanged<bool>? onUrgentChanged,
      // دوال لتبديل النموذج بين البديل والافتراضي:
      VoidCallback? onSelectAlternate,
      VoidCallback? onSelectDefault,
    }) {
  return DraggableScrollableSheet(
    initialChildSize: 0.17,
    minChildSize: 0.17,
    maxChildSize: 0.6,
    builder: (context, scrollController) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // صف خيارات الحجز
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // أيقونة النموذج البديل (UberX)
                _buildIconOption(
                  Icons.shopping_bag_rounded,
                  'ارسال اغراض',
                  Colors.blue,
                      () {
                    if (onSelectAlternate != null) {
                      onSelectAlternate();
                    }
                  },
                ),
                // أيقونات إعادة التعيين للنموذج الافتراضي (Uber Black)
                _buildIconOption(
                  Icons.airport_shuttle_outlined,
                  'ذهاب في رحلة',
                  Colors.black,
                      () {
                    if (onSelectDefault != null) {
                      onSelectDefault();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            // بناء الحقول حسب نوع النموذج
            if (isAlternateBooking) ...[
              // حقل الوزن
              _buildInputField(
                "الوزن",
                Icons.scale,
                TextInputType.number,
                controller: weightController,
              ),
              const SizedBox(height: 15),
              // حقل وصف العنصر (item_description)
              _buildInputField(
                "وصف العنصر",
                Icons.note,
                TextInputType.text,
                controller: notesController,
              ),
              const SizedBox(height: 15),
              // مفتاح لتحديد ما إذا كانت الحالة عاجلة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("عاجل"),
                  Switch(
                    value: urgent,
                    onChanged: onUrgentChanged,
                  ),
                ],
              ),
            ] else ...[
              // النموذج الافتراضي
              _buildInputField(
                "عدد الركاب",
                Icons.people,
                TextInputType.number,
                controller: passengersController,
              ),
              const SizedBox(height: 15),
              _buildDateField(
                context,
                "تاريخ الرحلة",
                Icons.calendar_today,
                controller: departureController,
              ),
              const SizedBox(height: 15),
              _buildInputField(
                "ملاحظات إضافية",
                Icons.note,
                TextInputType.multiline,
                controller: notesController,
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'تأكيد الحجز',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}
