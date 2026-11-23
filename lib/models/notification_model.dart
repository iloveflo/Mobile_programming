class NotificationModel {
  final int id;
  final int userId;
  final int? scheduleId;
  final String type;
  final String channel;
  final String title;
  final String message;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String status;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.scheduleId,
    required this.type,
    required this.channel,
    required this.title,
    required this.message,
    this.scheduledAt,
    this.sentAt,
    required this.status,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    int? parseNullableInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    DateTime? parseDate(String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString());
    }

    return NotificationModel(
      id: parseInt(json['notification_id'] ?? json['id']),
      userId: parseInt(json['user_id'] ?? json['userId']),
      scheduleId: parseNullableInt(json['schedule_id'] ?? json['scheduleId']),
      type: (json['notification_type'] ?? json['type'] ?? 'PAYMENT_REMINDER')
          .toString(),
      channel: (json['channel'] ?? 'PUSH').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      scheduledAt: parseDate('scheduled_at'),
      sentAt: parseDate('sent_at'),
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: parseDate('created_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'notification_id': id,
    'user_id': userId,
    'schedule_id': scheduleId,
    'notification_type': type,
    'channel': channel,
    'title': title,
    'message': message,
    'scheduled_at': scheduledAt?.toIso8601String(),
    'sent_at': sentAt?.toIso8601String(),
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };

  NotificationModel copyWith({
    int? id,
    int? userId,
    int? scheduleId,
    String? type,
    String? channel,
    String? title,
    String? message,
    DateTime? scheduledAt,
    DateTime? sentAt,
    String? status,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleId: scheduleId ?? this.scheduleId,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
