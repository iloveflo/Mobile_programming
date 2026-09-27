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
    DateTime? parseDate(String key) =>
        json[key] == null ? null : DateTime.parse(json[key] as String);

    return NotificationModel(
      id: json['notification_id'] as int,
      userId: json['user_id'] as int,
      scheduleId: json['schedule_id'] as int?,
      type: json['notification_type'] as String,
      channel: json['channel'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      scheduledAt: parseDate('scheduled_at'),
      sentAt: parseDate('sent_at'),
      status: json['status'] as String,
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
}
