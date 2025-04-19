import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  final Set<int> _shownNotifications = {};

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  /// جلب الإشعارات وعرض تنبيهات محلية ثم تعليمها كمقروء عند فتح الصفحة
  Future<void> loadNotifications() async {
    try {
      final list = await _service.getNotifications();

      // عرض محلي للإشعارات الجديدة غير المقروءة
      for (var notif in list.where((n) => !n.isRead && !_shownNotifications.contains(n.id))) {
        await _service.showLocalNotification(notif);
        _shownNotifications.add(notif.id);
      }

      // تعليم كل الإشعارات غير المقروءة كمقروءة في السيرفر
      for (var notif in list.where((n) => !n.isRead)) {
        await _service.markAsRead(notif.id);
      }

      // تحديث النسخة المحلية لتعكس حالة المقروءة
      _notifications = list.map((n) => n.isRead ? n : n.copyWith(isRead: true)).toList();
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      rethrow;
    }
  }

  /// معالجة تعليم إشعار كمقروء منفرداً (في حال الحاجة)
  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
      rethrow;
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
}
