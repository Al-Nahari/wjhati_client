// lib/services/notification_service.dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/ip.dart';
import 'AuthService.dart';

class NotificationService {
  static const String _basePath = '${ips.apiUrl}notifications/';

  final FlutterLocalNotificationsPlugin _localNotifPlugin =
  FlutterLocalNotificationsPlugin();

  NotificationService() {
    _initLocalNotifications();
  }

  void _initLocalNotifications() {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    _localNotifPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  /// عرض إشعار محلي
  Future<void> showLocalNotification(AppNotification notif) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'main_channel',
        'الإشعارات',
        channelDescription: 'تنبيهات التطبيق',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _localNotifPlugin.show(
      notif.id,
      notif.title,
      notif.message,
      details,
    );
  }

  /// جلب إشعارات المستخدم الحالي
  Future<List<AppNotification>> getNotifications() async {
    await AuthService.refreshToken();
    final headers = await AuthService.getAuthHeader();
    headers['Content-Type'] = 'application/json';


    final uri = Uri.parse('$_basePath');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل الإشعارات: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((e) => AppNotification.fromJson(e)).toList();
  }

  /// تعليم السيرفر بأن هذه الإشعار قد قُرئت
  Future<void> markAsRead(int notificationId) async {
    await AuthService.refreshToken();
    final headers = await AuthService.getAuthHeader();
    headers['Content-Type'] = 'application/json';

    final uri = Uri.parse('$_basePath$notificationId/');
    final body = json.encode({'is_read': true});

    final response = await http.patch(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('فشل تحديث حالة الإشعار: ${response.statusCode}');
    }
  }
}