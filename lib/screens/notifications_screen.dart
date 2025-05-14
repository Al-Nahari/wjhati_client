// lib/screens/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/notification_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // جلب الإشعارات أول مرة بعد بناء الـ widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          // أيقونة الإشعارات + Badge
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<NotificationProvider>().loadNotifications(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, prov, __) {
          final list = prov.notifications;
          if (list.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات.'));
          }
          return RefreshIndicator(
            onRefresh: prov.loadNotifications,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, idx) {
                final notif = list[idx];
                final formattedDate = DateFormat('yyyy-MM-dd – HH:mm', 'ar')
                    .format(notif.createdAt.toLocal());
                return Card(
                  color: notif.isRead ? Colors.grey[100] : Colors.white,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      notif.isRead ? Icons.mark_email_read : Icons.email,
                      color: notif.isRead ? Colors.grey : Colors.redAccent,
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight:
                        notif.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif.message),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                notif.notificationType,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => prov.markAsRead(notif.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
