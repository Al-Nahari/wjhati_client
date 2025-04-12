import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  /// نافذة الحجز مع تفصيل الحجز حسب نوعه (افتراضي أو بديل)
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
                    color: Color(0xFF4e54c8),
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
                            activeColor: const Color(0xFF4e54c8),
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
                    backgroundColor: const Color(0xFF4e54c8),
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
      endpoint = '${ips.apiUrl}cashe-item-deliveries/';
    } else {
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
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      drawer: AppDrawer(userData: {}),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // خريطة تغطي كامل الخلفية
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation?.coordinates ?? LatLng(24.7136, 46.6753),
              zoom: 13.0,
              // تمكين التفاعل الكامل (تكبير، تصغير، تدوير، سحب)
              interactiveFlags: InteractiveFlag.all,
              onPositionChanged: (MapPosition position, bool hasGesture) {
                // لا إعادة ضبط المركز تلقائيًا لمنع تعارض حركة المستخدم
              },
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
              // مؤشر الموقع الحالي
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
                          Icons.location_pin,
                          color: const Color(0xFF4e54c8),
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              // مؤشر الوجهة
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
                          color: Colors.red,
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
                      color: const Color(0xFF4e54c8).withOpacity(0.8),
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
            ],
          ),
          // SafeArea لاحتواء المحتوى فوق الخريطة
          SafeArea(
            child: Column(
              children: [
                // حقل البحث مصمم بنمط Uber مع تصميم عصري (لون تدرجي، ظلال، وزوايا دائرية)
                buildUberSearchBar(context, _destinationController),
              ],
            ),
          ),
          // مؤشر التحميل
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          // عناصر الأزرار أسفل الشاشة
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر إرسال أغراض
                ElevatedButton.icon(
                  onPressed: () {
                    _showBookingDialog(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4e54c8),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const FaIcon(
                    FontAwesomeIcons.box,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    "رسائل",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // زر العودة إلى الرئيسية
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  backgroundColor: Colors.white,
                  elevation: 6,
                  child: const Icon(
                    Icons.home,
                    color: Color(0xFF4e54c8),
                    size: 30,
                  ),
                ),
                // زر طلب رحلة
                ElevatedButton.icon(
                  onPressed: () {
                    _showBookingDialog(false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4e54c8),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const FaIcon(
                    FontAwesomeIcons.taxi,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    "رحلة",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// دالة تصميم حقل البحث بنمط Uber مع تصميم عصري
Widget buildUberSearchBar(BuildContext context, TextEditingController controller) {
  final screenHeight = MediaQuery.of(context).size.height;
  return Container(
    // ارتفاع يمثل 10% من الشاشة
    height: screenHeight * 0.1,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        // تأثير ظلال حديثة مشابهة لتطبيق Uber
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.search,
              color: Colors.grey,
              size: 28,
            ),
          ),
          // استخدام Widget مرن ليملأ المساحة المتبقية مثل Uber
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: "أين تريد الذهاب؟",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                // يمكنك استدعاء دالة البحث هنا
              },
            ),
          ),
          // زر مسح النص (اختياري)
          if(controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey, size: 24),
              onPressed: () {
                controller.clear();
              },
            ),
        ],
      ),
    ),
  );
}

/// Widget لحقل الإدخال مع تأثير الظلال وحواف ناعمة
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
        prefixIcon: Icon(icon, color: const Color(0xFF4e54c8)),
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

/// Widget لحقل اختيار التاريخ مع تأثير التمويه وخيارات تصميم متطورة
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
        prefixIcon: Icon(icon, color: const Color(0xFF4e54c8)),
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
                  primary: Color(0xFF4e54c8),
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4e54c8),
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

/// Provider خاص لتخزين الصور من الإنترنت مع caching
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
