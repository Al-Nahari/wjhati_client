import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// تأكد من استيراد AuthService من المسار المناسب في مشروعك
import '../services/AuthService.dart';
import 'TripScreen.dart';

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
      final url = Uri.parse('http://192.168.1.2:8000/bookings/');
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
      final url = Uri.parse('http://192.168.1.2:8000/bookings/$bookingId/');
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
