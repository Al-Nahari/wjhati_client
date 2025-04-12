import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// تأكد من استيراد AuthService من المسار المناسب في مشروعك
import '../services/AuthService.dart';
import '../services/ip.dart';
/// صفحة عرض قائمة الحجوزات مع إمكانية إلغاء الحجز والانتقال لتفاصيل الرحلة
class BookingsPage extends StatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  bool isLoading = true;
  List<dynamic> bookings = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  /// جلب الحجوزات من الخادم
  Future<void> _fetchBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();
      final url = Uri.parse('${ips.apiUrl}bookings/');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            bookings = data;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'تنسيق البيانات من الخادم غير صحيح.';
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

  /// إلغاء الحجز بعد تأكيد المستخدم
  Future<void> _cancelBooking(int bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();
      final url = Uri.parse('${ips.apiUrl}bookings/$bookingId/');
      final response = await http.patch(
        url,
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"status": "cancelled"}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء الحجز بنجاح')),
        );
        _fetchBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إلغاء الحجز: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إلغاء الحجز: $e')),
      );
    }
  }

  /// الانتقال إلى صفحة تفاصيل الرحلة باستخدام معرف الرحلة
  void _showTripDetails(int tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsPage(tripId: tripId),
      ),
    );
  }

  /// بناء بطاقة عرض تفاصيل كل حجز
  Widget _buildBookingItem(dynamic booking) {
    final bool cancelled = booking['status'] == 'cancelled';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رقم الحجز: ${booking['id']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    booking['status'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: cancelled ? Colors.redAccent : Colors.green,
                ),
                const Spacer(),
                Text('السعر: ${booking['total_price']}'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: cancelled ? null : () => _cancelBooking(booking['id']),
                  child: const Text('إلغاء الحجز'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showTripDetails(booking['trip']),
                  child: const Text('عرض الرحلة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قائمة الحجوزات مع إمكانية التحديث بالسحب
  Widget _buildBookingsList() {
    if (bookings.isEmpty) {
      return const Center(child: Text('لا توجد حجوزات.'));
    }
    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildBookingItem(bookings[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع الحجوزات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookings,
          ),
        ],
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
          : _buildBookingsList(),
    );
  }
}

/// صفحة تفاصيل الرحلة مع تتبع المسار باستخدام MQTT
class TripDetailsPage extends StatefulWidget {
  final int tripId;
  const TripDetailsPage({Key? key, required this.tripId}) : super(key: key);

  @override
  _TripDetailsPageState createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  late MqttChannelService _mqttChannelService;
  // قائمة لتخزين بيانات الرحلة الواردة (JSON)
  List<Map<String, dynamic>> _trips = [];
  // قائمة نقاط المسار لرسمه على الخريطة
  List<LatLng> _route = [];
  // متحكم الخريطة
  final MapController _mapController = MapController();
  late StreamSubscription<String> _subscription;

  @override
  void initState() {
    super.initState();
    _mqttChannelService = MqttChannelService();
    // الاشتراك في القناة لاستقبال الرسائل
    _subscription = _mqttChannelService.messageStream.listen((message) {
      _handleMessage(message);
    });
    _mqttChannelService.connect();
  }

  // دالة لمعالجة الرسائل الواردة من القناة
  void _handleMessage(String message) {
    // تقسيم الرسالة إلى أسطر للبحث عن تنسيق JSON صالح
    List<String> lines = message.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('{') && line.endsWith('}')) {
        try {
          Map<String, dynamic> data = jsonDecode(line);
          double? lat = _parseCoordinate(data['lat']);
          double? lng = _parseCoordinate(data['lng']);
          if (lat != null && lng != null) {
            setState(() {
              _trips.add(data);
              _route.add(LatLng(lat, lng));
            });
            // تحديث موقع الكاميرا إلى الموقع الجديد
            _mapController.move(LatLng(lat, lng), 15);
          }
        } catch (e) {
          print("خطأ في فك تشفير JSON: $e");
        }
      } else {
        print("الرسالة ليست بتنسيق JSON: $line");
      }
    }
  }

  double? _parseCoordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print("خطأ في تحويل الإحداثية: $value");
        return null;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    _mqttChannelService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تحديد مركز الخريطة بناءً على آخر نقطة تم استقبالها
    LatLng center = _route.isNotEmpty ? _route.last : LatLng(0.0, 0.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الرحلة'),
      ),
      body: Container(
        decoration: BoxDecoration(
          // خلفية بتدرج لوني جذاب
          gradient: LinearGradient(
            colors: [Colors.black, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // الجزء العلوي: عرض الخريطة مع تتبع المسار
            Expanded(
              flex: 2,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: center,
                  zoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route,
                        strokeWidth: 4.0,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: _route.isNotEmpty
                        ? [
                      Marker(
                        point: _route.last,
                        width: 80,
                        height: 80,
                        builder: (context) => const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                    ]
                        : [],
                  ),
                ],
              ),
            ),
            // الجزء السفلي: عرض قائمة بيانات الرحلة المستلمة
            Expanded(
              flex: 1,
              child: _trips.isEmpty
                  ? const Center(
                child: Text(
                  'في انتظار بيانات الرحلة...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
                  : ListView.builder(
                itemCount: _trips.length,
                itemBuilder: (context, index) {
                  final trip = _trips[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(
                        Icons.navigation,
                        color: Colors.deepPurple,
                      ),
                      title: Text(
                        "Lat: ${trip['lat']}\nLng: ${trip['lng']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        "Altitude: ${trip['altitude'] ?? 'N/A'}\nSpeed: ${trip['speed'] ?? 'N/A'}",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// خدمة MQTT تستخدم قناة (Channel) لتوزيع الرسائل الواردة
class MqttChannelService {
  // بيانات خادم HiveMQ Cloud
  final String server = 'nahari-m1qoxs.a03.euc1.aws.hivemq.cloud';
  final int port = 8883; // المنفذ الآمن
  final String clientId = 'flutter_modern_ui_client';
  // بيانات الاعتماد (استبدلها ببيانات حسابك)
  final String username = 'hivemq.client.1740007217404';
  final String password = 'N@VG3:C7dBh#Qgze0<j5';

  late MqttServerClient client;
  final StreamController<String> _messageController =
  StreamController<String>.broadcast();

  // تدفق الرسائل العام (Channel)
  Stream<String> get messageStream => _messageController.stream;

  MqttChannelService() {
    client = MqttServerClient.withPort(server, clientId, port)
      ..secure = true
      ..keepAlivePeriod = 20
      ..logging(on: true)
      ..onConnected = onConnected
      ..onDisconnected = onDisconnected
      ..onSubscribed = onSubscribed;
  }

  Future<void> connect() async {
    try {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ تم الاتصال بـ MQTT Broker');
        subscribeToTopic('flutter/test');
      } else {
        print('❌ فشل الاتصال: ${client.connectionStatus}');
        disconnect();
      }
    } catch (e) {
      print('❌ خطأ أثناء الاتصال: $e');
      disconnect();
    }
  }

  void disconnect() {
    client.disconnect();
    print('❌ تم قطع الاتصال');
    _messageController.close();
  }

  void onConnected() {
    print('✅ تم الاتصال بنجاح');
  }

  void onDisconnected() {
    print('❌ تم قطع الاتصال');
  }

  void onSubscribed(String topic) {
    print('✅ تم الاشتراك في الموضوع: $topic');
  }

  void subscribeToTopic(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final recMess = events[0].payload as MqttPublishMessage;
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('📩 رسالة جديدة من $topic: $pt');
      _messageController.sink.add(pt);
    });
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print('📤 تم إرسال: $message إلى $topic');
  }
}
