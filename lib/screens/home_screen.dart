import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/wallet_screen.dart';

import '../main.dart';
import '../widgets/drawer.dart';
import '../widgets/top_navigation.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../services/ip.dart';

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
  bool _isLoading = false;

  // لتحديد نوع الحجز: false للنموذج الافتراضي و true للنموذج البديل
  bool _isAlternateBooking = false;
  bool _urgent = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  /// الحصول على الموقع الحالي باستخدام Geolocator
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

  void _onDestinationSelected(Location location) {
    setState(() {
      _routePoints = [];
      _destinationLocation = location;
      _destinationController.text = location.name;
      _searchSuggestions.clear();
    });
    _getRouteDirections();
  }

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

  /// الدالة التي تعرض نافذة الحجز في منتصف الشاشة بحسب نوع الحجز
  void _showBookingDialog(bool alternateBooking) {
    setState(() {
      _isAlternateBooking = alternateBooking;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              title: Center(
                child: Text(
                  alternateBooking ? 'تفاصيل حجز إرسال أغراض' : 'تفاصيل حجز رحلة',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MyApp.primry,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (alternateBooking) ...[
                      _buildInputField(
                        "الوزن",
                        Icons.scale,
                        TextInputType.number,
                        controller: _weightController,
                      ),
                      const SizedBox(height: 15),
                      _buildInputField(
                        "وصف العنصر",
                        Icons.note,
                        TextInputType.text,
                        controller: _notesController,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "عاجل",
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: _urgent,
                            onChanged: (value) {
                              setStateDialog(() {
                                _urgent = value;
                              });
                            },
                            activeColor: MyApp.primry,
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildInputField(
                        "عدد الركاب",
                        Icons.people,
                        TextInputType.number,
                        controller: _passengersController,
                      ),
                      const SizedBox(height: 15),
                      _buildDateField(
                        context,
                        "تاريخ الرحلة",
                        Icons.calendar_today,
                        controller: _departureTimeController,
                      ),
                      const SizedBox(height: 15),
                      _buildInputField(
                        "ملاحظات إضافية",
                        Icons.note,
                        TextInputType.multiline,
                        controller: _notesController,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "إلغاء",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _sendBooking();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.primry,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "تأكيد الحجز",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendBooking() async {
    if (_currentLocation == null || _destinationLocation == null) {
      _showSnackBar("الموقع الحالي أو الوجهة غير محددة");
      return;
    }

    Map<String, dynamic> bookingData;
    String endpoint;

    if (_isAlternateBooking) {
      final now = DateTime.now().toUtc().toIso8601String();
      bookingData = {
        "id": 1,
        "created_at": now,
        "updated_at": now,
        "from_location": "${_currentLocation!.coordinates.latitude}, ${_currentLocation!.coordinates.longitude}",
        "to_location": "${_destinationLocation!.coordinates.latitude}, ${_destinationLocation!.coordinates.longitude}",
        "item_description": _notesController.text.trim(),
        "weight": _weightController.text.trim(),
        "urgent": _urgent,
        "status": "pending",
        "user": 1
      };
      endpoint = '${ips.apiUrl}cashe-item-deliveries/';
    } else {
      String departureTime = _departureTimeController.text.trim();
      int passengers = int.tryParse(_passengersController.text.trim()) ?? 1;
      String notes = _notesController.text.trim();

      if (departureTime.isEmpty) {
        departureTime = "2025-02-04T00:50:16Z";
      }

      bookingData = {
        "from_location": "${_currentLocation!.coordinates.latitude}, ${_currentLocation!.coordinates.longitude}",
        "to_location": "${_destinationLocation!.coordinates.latitude}, ${_destinationLocation!.coordinates.longitude}",
        "departure_time": departureTime,
        "passengers": passengers,
        "notes": notes,
        "user": 1
      };
      endpoint = '${ips.apiUrl}cashe-bookings/';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(userData: {}),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // عرض الخريطة
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation?.coordinates ?? LatLng(24.7136, 46.6753),
              zoom: 13.0,
              interactiveFlags: InteractiveFlag.all,
              onPositionChanged: (MapPosition position, bool hasGesture) {},
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
              // المؤشر للموقع الحالي
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!.coordinates,
                      builder: (ctx) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.account_circle,
                          color: MyApp.primry,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              // المؤشر للوجهة
              if (_destinationLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _destinationLocation!.coordinates,
                      builder: (ctx) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.location_on,
                          color: MyApp.primry,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              // رسم الطريق بين الموقع الحالي والوجهة
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: MyApp.primry.withOpacity(0.8),
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
            ],
          ),
          // وضع شريط البحث في أعلى الشاشة
          Positioned(
            top: 60,
            left: 30,
            right: 30,
            child: buildTopNavigation(
              context,
              _destinationController,
              _searchSuggestions,
              _onDestinationSelected,
              _searchLocations,
            ),
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),
          // أزرار الحجز في أسفل الشاشة
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _showBookingDialog(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyApp.primry,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.box, color: Colors.white, size: 18),
                    label: const Text(
                      "رسائل",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // زر المنزل في وسط أسفل الشاشة
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WalletPage()),
                      );
                    },
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: const Icon(
                      Icons.home,
                      color: MyApp.primry,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showBookingDialog(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyApp.primry,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.taxi, color: Colors.white, size: 18),
                    label: const Text(
                      "رحلة",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// موفر تبليط الخريطة مع كاش الصور
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

/// حقل إدخال نص مع تأثير التمويه وخلفية شفافة
Widget _buildInputField(String hintText, IconData icon, TextInputType keyboardType,
    {TextEditingController? controller}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(16),
    ),
    child: TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: MyApp.primry),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
    ),
  );
}

/// حقل اختيار تاريخ مع تأثير التمويه
Widget _buildDateField(BuildContext context, String hintText, IconData icon,
    {required TextEditingController controller}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(16),
    ),
    child: TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: MyApp.primry),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: MyApp.primry,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: MyApp.primry,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          controller.text = pickedDate.toUtc().toIso8601String();
        }
      },
    ),
  );
}
