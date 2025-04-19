class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String notificationType;
  final int? relatedObjectId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.notificationType,
    this.relatedObjectId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      notificationType: json['notification_type']?.toString() ?? '',
      relatedObjectId: json['related_object_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      notificationType: notificationType,
      relatedObjectId: relatedObjectId,
      createdAt: createdAt,
    );
  }
}
